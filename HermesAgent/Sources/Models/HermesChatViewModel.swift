//
//  HermesChatViewModel.swift
//  HermesAgent
//
//  Chat state management with streaming message support.
//

import Foundation
import Combine

// MARK: - Hermes Message Model

struct HermesMessage: Identifiable, Equatable {
    let id: String
    let content: String
    let isUser: Bool
    let timestamp: Date
    var isStreaming: Bool

    init(id: String = UUID().uuidString, content: String, isUser: Bool, timestamp: Date = Date(), isStreaming: Bool = false) {
        self.id = id
        self.content = content
        self.isUser = isUser
        self.timestamp = timestamp
        self.isStreaming = isStreaming
    }
}

// MARK: - HermesChatViewModel

class HermesChatViewModel: ObservableObject {
    @Published var messages: [HermesMessage] = []
    @Published var isTyping = false
    @Published var currentStreamId: String?

    private var cancellables = Set<AnyCancellable>()

    init() {
        NotificationCenter.default.publisher(for: .hermesMessage)
            .compactMap { $0.userInfo as? [String: Any] }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] json in
                self?.handleMessage(json)
            }
            .store(in: &cancellables)

        messages.append(HermesMessage(
            content: "⚡ Welcome to Hermes Agent by Nous Research!\n\nConnect to your self-hosted Hermes gateway to start chatting. Your agent learns from every interaction.",
            isUser: false
        ))
    }

    // MARK: - Send

    func sendMessage(_ text: String, via agent: HermesAgentManager) {
        if text.hasPrefix("/") {
            agent.sendSlashCommand(text)
            messages.append(HermesMessage(content: text, isUser: true))
            return
        }

        messages.append(HermesMessage(content: text, isUser: true))
        isTyping = true
        agent.sendText(text)

        DispatchQueue.main.asyncAfter(deadline: .now() + 60) { [weak self] in
            self?.isTyping = false
        }
    }

    // MARK: - Message Handler

    private func handleMessage(_ json: [String: Any]) {
        let msgType = json["type"] as? String ?? ""

        switch msgType {
        case "response", "agent_response", "message":
            isTyping = false
            let contentStr = (json["content"] as? String) ?? (json["text"] as? String)
            if let content = contentStr {
                messages.append(HermesMessage(content: content, isUser: false))
            }

        case "stream_start":
            isTyping = false
            let streamId = json["stream_id"] as? String ?? UUID().uuidString
            currentStreamId = streamId
            messages.append(HermesMessage(id: streamId, content: "", isUser: false, isStreaming: true))

        case "stream_chunk", "stream":
            let chunkStr = (json["content"] as? String) ?? (json["chunk"] as? String)
            if let chunk = chunkStr,
               let streamId = currentStreamId,
               let idx = messages.firstIndex(where: { $0.id == streamId }) {
                let oldMsg = messages[idx]
                messages[idx] = HermesMessage(
                    id: streamId,
                    content: oldMsg.content + chunk,
                    isUser: false,
                    timestamp: oldMsg.timestamp,
                    isStreaming: true
                )
            }

        case "stream_end":
            isTyping = false
            if let streamId = currentStreamId,
               let idx = messages.firstIndex(where: { $0.id == streamId }) {
                messages[idx] = HermesMessage(
                    id: streamId,
                    content: messages[idx].content,
                    isUser: false,
                    timestamp: messages[idx].timestamp,
                    isStreaming: false
                )
            }
            currentStreamId = nil

        case "typing":
            isTyping = true

        case "typing_stop":
            isTyping = false

        case "skill_created", "skill_updated":
            let name = json["name"] as? String ?? "unknown"
            let action = msgType == "skill_created" ? "created" : "updated"
            messages.append(HermesMessage(content: "🧠 Skill \(action): \(name)", isUser: false))

        case "memory_updated":
            messages.append(HermesMessage(content: "💾 Memory updated", isUser: false))

        case "tool_use":
            let tool = json["tool"] as? String ?? "unknown"
            messages.append(HermesMessage(content: "🔧 Using tool: \(tool)", isUser: false))

        case "error":
            isTyping = false
            let errorMsg = json["message"] as? String ?? json["error"] as? String ?? "Unknown error"
            messages.append(HermesMessage(content: "⚠️ \(errorMsg)", isUser: false))

        default:
            if let content = json["content"] as? String {
                isTyping = false
                messages.append(HermesMessage(content: content, isUser: false))
            }
        }
    }
}
