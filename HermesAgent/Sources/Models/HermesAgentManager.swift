//
//  HermesAgentManager.swift
//  HermesAgent
//
//  Manages WebSocket connections to the Hermes Agent gateway.
//

import Foundation
import Combine

// MARK: - HermesAgentManager

/// Handles WebSocket lifecycle, message sending/receiving, keep-alive pings,
/// auto-reconnection, and persists the server URL in `UserDefaults`.
class HermesAgentManager: ObservableObject {

    // MARK: Published State

    @Published var isConnected = false
    @Published var isConnecting = false
    @Published var serverURL: String = ""
    @Published var lastError: String?
    @Published var agentStatus: AgentStatus = .disconnected

    // MARK: Private

    private var webSocket: URLSessionWebSocketTask?
    private var session: URLSession?
    private var pingTimer: Timer?

    // MARK: - Agent Status

    /// Represents the current connection/activity state of the agent.
    enum AgentStatus: String {
        case disconnected = "Disconnected"
        case connecting = "Connecting..."
        case connected = "Connected"
        case chatting = "Active"
    }

    // MARK: - Connection

    /// Connect to a Hermes gateway via its URL.
    /// Automatically normalizes HTTP(S) to WS(S) and appends `/ws` if needed.
    func connect(url: String) {
        guard !isConnecting else { return }
        isConnecting = true
        agentStatus = .connecting
        lastError = nil

        var wsURL = url
        // Normalize URL to ws endpoint
        if wsURL.hasPrefix("http://") {
            wsURL = wsURL.replacingOccurrences(of: "http://", with: "ws://")
        } else if wsURL.hasPrefix("https://") {
            wsURL = wsURL.replacingOccurrences(of: "https://", with: "wss://")
        } else if !wsURL.hasPrefix("ws://") && !wsURL.hasPrefix("wss://") {
            wsURL = "ws://\(wsURL)"
        }

        // Append gateway WS path if not present
        if !wsURL.contains("/ws") {
            wsURL += "/ws"
        }

        serverURL = url

        guard let url = URL(string: wsURL) else {
            lastError = "Invalid URL"
            isConnecting = false
            agentStatus = .disconnected
            return
        }

        let config = URLSessionConfiguration.default
        config.waitsForConnectivity = true
        session = URLSession(configuration: config)
        webSocket = session?.webSocketTask(with: url)

        webSocket?.resume()
        isConnecting = false
        isConnected = true
        agentStatus = .connected

        receiveMessage()
        startPing()

        // Send hello/handshake
        let hello: [String: Any] = [
            "type": "hello",
            "platform": "ios",
            "version": "1.0.0",
            "client": "hermes-ios"
        ]
        sendJSON(hello)

        // Persist URL for auto-reconnect
        UserDefaults.standard.set(serverURL, forKey: "hermes_server_url")
    }

    /// Gracefully disconnect from the gateway.
    func disconnect() {
        pingTimer?.invalidate()
        webSocket?.cancel(with: .normalClosure, reason: nil)
        webSocket = nil
        isConnected = false
        agentStatus = .disconnected
    }

    // MARK: - Messaging

    /// Send a user text message.
    func sendText(_ text: String) {
        agentStatus = .chatting
        let msg: [String: Any] = [
            "type": "user_message",
            "content": text,
            "timestamp": ISO8601DateFormatter().string(from: Date())
        ]
        sendJSON(msg)
    }

    /// Send a slash command (e.g. `/new`, `/model`).
    func sendSlashCommand(_ command: String) {
        let msg: [String: Any] = [
            "type": "command",
            "command": command,
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
                print("[Hermes] Send error: \(error)")
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
                self?.receiveMessage()

            case .failure(let error):
                print("[Hermes] Receive error: \(error)")
                DispatchQueue.main.async {
                    self?.handleDisconnect()
                }
            }
        }
    }

    private func handleIncoming(_ text: String) {
        guard let data = text.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return }

        DispatchQueue.main.async { [weak self] in
            self?.agentStatus = .connected
            NotificationCenter.default.post(
                name: .hermesMessage,
                object: nil,
                userInfo: json
            )
        }
    }

    // MARK: - Reconnect & Keep Alive

    private func handleDisconnect() {
        isConnected = false
        agentStatus = .disconnected

        // Auto reconnect after 5 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) { [weak self] in
            guard let self = self, !self.isConnected, !self.serverURL.isEmpty else { return }
            self.connect(url: self.serverURL)
        }
    }

    private func startPing() {
        pingTimer?.invalidate()
        pingTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            self?.webSocket?.sendPing { error in
                if let error = error {
                    print("[Hermes] Ping failed: \(error)")
                    DispatchQueue.main.async {
                        self?.handleDisconnect()
                    }
                }
            }
        }
    }

    /// Attempt to reconnect using a previously saved URL.
    func tryAutoConnect() {
        if let saved = UserDefaults.standard.string(forKey: "hermes_server_url"), !saved.isEmpty {
            connect(url: saved)
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let hermesMessage = Notification.Name("hermesMessage")
}
