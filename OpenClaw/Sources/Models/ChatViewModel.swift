//
//  ChatViewModel.swift
//  OpenClaw
//
//  Manages chat message state and processes incoming gateway events.
//

import Foundation
import Combine

// MARK: - Chat Message Model

/// A single chat message in the OpenClaw conversation.
struct ChatMessage: Identifiable, Equatable {
    let id: String
    let content: String
    let isUser: Bool
    let timestamp: Date

    init(id: String = UUID().uuidString, content: String, isUser: Bool, timestamp: Date = Date()) {
        self.id = id
        self.content = content
        self.isUser = isUser
        self.timestamp = timestamp
    }
}

// MARK: - ChatViewModel

/// Observes gateway messages via `NotificationCenter` and maintains
/// the ordered list of chat messages for the UI.
class ChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var isTyping = false

    private var cancellables = Set<AnyCancellable>()

    init() {
        // Subscribe to incoming gateway messages
        NotificationCenter.default.publisher(for: .gatewayMessage)
            .compactMap { $0.userInfo as? [String: Any] }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] json in
                self?.handleGatewayMessage(json)
            }
            .store(in: &cancellables)

        // Welcome message
        messages.append(ChatMessage(
            content: "🦞 Welcome to OpenClaw! I'm your personal AI assistant. Connect to a gateway to start chatting.",
            isUser: false
        ))
    }

    // MARK: - Send

    /// Send a user message and show typing indicator.
    func sendMessage(_ text: String, via gateway: GatewayManager) {
        let userMsg = ChatMessage(content: text, isUser: true)
        messages.append(userMsg)

        isTyping = true
        gateway.sendText(text)

        // Fallback timeout for typing indicator
        DispatchQueue.main.asyncAfter(deadline: .now() + 30) { [weak self] in
            self?.isTyping = false
        }
    }

    // MARK: - Receive

    private func handleGatewayMessage(_ json: [String: Any]) {
        let msgType = json["type"] as? String ?? ""

        switch msgType {
        case "message", "response", "agent.response":
            isTyping = false
            if let content = json["content"] as? String ?? json["text"] as? String {
                let msg = ChatMessage(content: content, isUser: false)
                messages.append(msg)
            }

        case "typing", "agent.typing":
            isTyping = true

        case "typing.stop", "agent.typing.stop":
            isTyping = false

        case "error":
            isTyping = false
            let errorMsg = json["message"] as? String ?? "Unknown error"
            messages.append(ChatMessage(content: "⚠️ \(errorMsg)", isUser: false))

        case "node.invoke":
            handleNodeInvoke(json)

        default:
            // Forward any message with a content field
            if let content = json["content"] as? String {
                isTyping = false
                messages.append(ChatMessage(content: content, isUser: false))
            }
        }
    }

    // MARK: - Node Invoke

    private func handleNodeInvoke(_ json: [String: Any]) {
        let command = json["command"] as? String ?? ""
        switch command {
        case "canvas.navigate", "canvas.eval", "canvas.snapshot":
            messages.append(ChatMessage(content: "📱 Canvas command: \(command)", isUser: false))
        case "camera.capture":
            messages.append(ChatMessage(content: "📷 Camera capture requested", isUser: false))
        case "location.get":
            messages.append(ChatMessage(content: "📍 Location requested", isUser: false))
        default:
            messages.append(ChatMessage(content: "🔧 Node command: \(command)", isUser: false))
        }
    }
}
