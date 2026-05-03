//
//  GatewayManager.swift
//  OpenClaw
//
//  Manages Bonjour discovery and WebSocket connections to OpenClaw gateways.
//

import Foundation
import Network
import Combine

// MARK: - Models

/// A gateway instance discovered via Bonjour or entered manually.
struct DiscoveredGateway: Identifiable, Equatable {
    let id: String
    let name: String
    let host: String
    let port: Int
}

// MARK: - GatewayManager

/// Handles mDNS/Bonjour gateway discovery, WebSocket lifecycle,
/// keep-alive pings, and automatic reconnection.
class GatewayManager: ObservableObject {
    // MARK: Published State

    @Published var isConnected = false
    @Published var isConnecting = false
    @Published var isSearching = false
    @Published var discoveredGateways: [DiscoveredGateway] = []
    @Published var lastError: String?
    @Published var currentHost: String?
    @Published var currentPort: Int = 18789

    // MARK: Private

    private var webSocket: URLSessionWebSocketTask?
    private var session: URLSession?
    private var browser: NWBrowser?
    private var pingTimer: Timer?
    private var reconnectTimer: Timer?

    // MARK: - Bonjour Discovery

    /// Start browsing for `_openclaw-gw._tcp` services on the local network.
    func startDiscovery() {
        isSearching = true
        let params = NWParameters()
        params.includePeerToPeer = true

        browser = NWBrowser(for: .bonjour(type: "_openclaw-gw._tcp", domain: "local."), using: params)
        browser?.browseResultsChangedHandler = { [weak self] results, _ in
            DispatchQueue.main.async {
                self?.handleBrowseResults(results)
            }
        }
        browser?.stateUpdateHandler = { [weak self] state in
            DispatchQueue.main.async {
                switch state {
                case .ready:
                    self?.isSearching = true
                case .failed(let error):
                    print("[OpenClaw] Browser failed: \(error)")
                    self?.isSearching = false
                case .cancelled:
                    self?.isSearching = false
                default:
                    break
                }
            }
        }
        browser?.start(queue: .main)

        // Stop searching indicator after timeout
        DispatchQueue.main.asyncAfter(deadline: .now() + 10) { [weak self] in
            self?.isSearching = false
        }
    }

    private func handleBrowseResults(_ results: Set<NWBrowser.Result>) {
        var gateways: [DiscoveredGateway] = []
        for result in results {
            if case .service(let name, _, _, _) = result.endpoint {
                let params = NWParameters.tcp
                let connection = NWConnection(to: result.endpoint, using: params)
                connection.stateUpdateHandler = { [weak self] state in
                    if case .ready = state {
                        if let endpoint = connection.currentPath?.remoteEndpoint,
                           case .hostPort(let host, let port) = endpoint {
                            let gw = DiscoveredGateway(
                                id: name,
                                name: name,
                                host: "\(host)",
                                port: Int(port.rawValue)
                            )
                            DispatchQueue.main.async {
                                if !(self?.discoveredGateways.contains(gw) ?? false) {
                                    self?.discoveredGateways.append(gw)
                                }
                            }
                        }
                        connection.cancel()
                    }
                }
                connection.start(queue: .global())

                // Fallback: add with name only (resolved address may arrive later)
                gateways.append(DiscoveredGateway(
                    id: name,
                    name: name,
                    host: name,
                    port: 18789
                ))
            }
        }
        discoveredGateways = gateways
    }

    // MARK: - WebSocket Connection

    /// Connect to a discovered gateway.
    func connect(to gateway: DiscoveredGateway) {
        connect(host: gateway.host, port: gateway.port)
    }

    /// Open a WebSocket connection to the specified host and port.
    func connect(host: String, port: Int) {
        guard !isConnecting else { return }
        isConnecting = true
        lastError = nil
        currentHost = host
        currentPort = port

        let urlString = "ws://\(host):\(port)/ws/node"
        guard let url = URL(string: urlString) else {
            lastError = "Invalid URL: \(urlString)"
            isConnecting = false
            return
        }

        let config = URLSessionConfiguration.default
        config.waitsForConnectivity = true
        session = URLSession(configuration: config)
        webSocket = session?.webSocketTask(with: url)

        webSocket?.resume()
        isConnecting = false
        isConnected = true

        receiveMessage()
        startPing()

        // Register this iOS device as a node with available capabilities
        let registration: [String: Any] = [
            "type": "node.register",
            "capabilities": ["canvas", "camera", "screen", "location", "talk"],
            "platform": "ios",
            "version": "1.0.0"
        ]
        sendJSON(registration)
    }

    /// Gracefully close the WebSocket connection.
    func disconnect() {
        pingTimer?.invalidate()
        reconnectTimer?.invalidate()
        webSocket?.cancel(with: .normalClosure, reason: nil)
        webSocket = nil
        isConnected = false
        currentHost = nil
    }

    // MARK: - Messaging

    /// Send a user text message to the gateway.
    func sendText(_ text: String) {
        let msg: [String: Any] = [
            "type": "message",
            "content": text,
            "timestamp": ISO8601DateFormatter().string(from: Date())
        ]
        sendJSON(msg)
    }

    /// Serialize a dictionary to JSON and send over the WebSocket.
    func sendJSON(_ dict: [String: Any]) {
        guard let data = try? JSONSerialization.data(withJSONObject: dict),
              let str = String(data: data, encoding: .utf8) else { return }

        webSocket?.send(.string(str)) { [weak self] error in
            if let error = error {
                print("[OpenClaw] Send error: \(error)")
                DispatchQueue.main.async {
                    self?.handleDisconnect()
                }
            }
        }
    }

    // MARK: - Receive Loop

    private func receiveMessage() {
        webSocket?.receive { [weak self] result in
            switch result {
            case .success(let message):
                switch message {
                case .string(let text):
                    self?.handleIncoming(text)
                case .data(let data):
                    if let text = String(data: data, encoding: .utf8) {
                        self?.handleIncoming(text)
                    }
                @unknown default:
                    break
                }
                // Continue listening for the next message
                self?.receiveMessage()

            case .failure(let error):
                print("[OpenClaw] Receive error: \(error)")
                DispatchQueue.main.async {
                    self?.handleDisconnect()
                }
            }
        }
    }

    private func handleIncoming(_ text: String) {
        guard let data = text.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return }

        DispatchQueue.main.async {
            NotificationCenter.default.post(
                name: .gatewayMessage,
                object: nil,
                userInfo: json
            )
        }
    }

    private func handleDisconnect() {
        isConnected = false
        scheduleReconnect()
    }

    // MARK: - Keep Alive & Reconnect

    private func startPing() {
        pingTimer?.invalidate()
        pingTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            self?.webSocket?.sendPing { error in
                if let error = error {
                    print("[OpenClaw] Ping failed: \(error)")
                    DispatchQueue.main.async {
                        self?.handleDisconnect()
                    }
                }
            }
        }
    }

    private func scheduleReconnect() {
        guard let host = currentHost else { return }
        reconnectTimer?.invalidate()
        reconnectTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: false) { [weak self] _ in
            guard let self = self, !self.isConnected else { return }
            self.connect(host: host, port: self.currentPort)
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let gatewayMessage = Notification.Name("gatewayMessage")
}
