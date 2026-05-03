//
//  ChatView.swift
//  OpenClaw
//
//  Real-time chat interface, message bubbles, typing indicator, and settings.
//

import SwiftUI

// MARK: - Chat View

/// Main chat screen with scrolling message list, typing indicator, and input bar.
struct ChatView: View {
    @EnvironmentObject var gateway: GatewayManager
    @EnvironmentObject var chatVM: ChatViewModel
    @State private var messageText = ""
    @State private var showSettings = false
    @FocusState private var isInputFocused: Bool

    var body: some View {
        NavigationView {
            ZStack {
                Color(red: 0.05, green: 0.05, blue: 0.10)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Messages
                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(chatVM.messages) { message in
                                    MessageBubble(message: message)
                                        .id(message.id)
                                }

                                if chatVM.isTyping {
                                    TypingIndicator()
                                        .id("typing")
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                        }
                        .onChange(of: chatVM.messages.count) { _ in
                            withAnimation(.easeOut(duration: 0.2)) {
                                if chatVM.isTyping {
                                    proxy.scrollTo("typing", anchor: .bottom)
                                } else if let last = chatVM.messages.last {
                                    proxy.scrollTo(last.id, anchor: .bottom)
                                }
                            }
                        }
                    }

                    // Input bar
                    inputBar
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    VStack(spacing: 2) {
                        Text("🦞 OpenClaw")
                            .font(.headline)
                            .foregroundColor(.white)
                        HStack(spacing: 4) {
                            Circle()
                                .fill(gateway.isConnected ? Color.green : Color.red)
                                .frame(width: 6, height: 6)
                            Text(gateway.isConnected ? "Connected" : "Disconnected")
                                .font(.caption2)
                                .foregroundColor(.gray)
                        }
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .foregroundColor(.orange)
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
        }
    }

    // MARK: - Input Bar

    private var inputBar: some View {
        HStack(spacing: 12) {
            TextField("Message OpenClaw...", text: $messageText, axis: .vertical)
                .lineLimit(1...5)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color.white.opacity(0.08))
                .cornerRadius(20)
                .foregroundColor(.white)
                .focused($isInputFocused)

            Button {
                sendMessage()
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(sendButtonStyle)
            }
            .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            Color(red: 0.08, green: 0.08, blue: 0.12)
                .overlay(
                    Rectangle()
                        .fill(Color.white.opacity(0.05))
                        .frame(height: 0.5),
                    alignment: .top
                )
        )
    }

    private func sendMessage() {
        let text = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        messageText = ""
        chatVM.sendMessage(text, via: gateway)
    }

    private var sendButtonStyle: AnyShapeStyle {
        if messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return AnyShapeStyle(Color.gray)
        } else {
            return AnyShapeStyle(LinearGradient(colors: [.orange, .red], startPoint: .top, endPoint: .bottom))
        }
    }
}

// MARK: - Message Bubble

/// A chat bubble styled differently for user vs. assistant messages.
struct MessageBubble: View {
    let message: ChatMessage

    var body: some View {
        HStack {
            if message.isUser { Spacer(minLength: 60) }

            VStack(alignment: message.isUser ? .trailing : .leading, spacing: 4) {
                Text(message.content)
                    .font(.body)
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        Group {
                            if message.isUser {
                                LinearGradient(colors: [.orange, .red.opacity(0.9)], startPoint: .topLeading, endPoint: .bottomTrailing)
                            } else {
                                Color.white.opacity(0.1)
                            }
                        }
                    )
                    .cornerRadius(18)

                Text(message.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundColor(.gray.opacity(0.6))
            }

            if !message.isUser { Spacer(minLength: 60) }
        }
    }
}

// MARK: - Typing Indicator

/// Animated bouncing dots to indicate the assistant is composing a response.
struct TypingIndicator: View {
    @State private var dotOffset: [CGFloat] = [0, 0, 0]

    var body: some View {
        HStack {
            HStack(spacing: 4) {
                ForEach(0..<3) { i in
                    Circle()
                        .fill(Color.orange.opacity(0.6))
                        .frame(width: 8, height: 8)
                        .offset(y: dotOffset[i])
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.white.opacity(0.08))
            .cornerRadius(18)
            .onAppear {
                for i in 0..<3 {
                    withAnimation(.easeInOut(duration: 0.5).repeatForever().delay(Double(i) * 0.15)) {
                        dotOffset[i] = -6
                    }
                }
            }
            Spacer()
        }
    }
}

// MARK: - Settings View

/// Displays gateway connection info, disconnect action, and app metadata.
struct SettingsView: View {
    @EnvironmentObject var gateway: GatewayManager
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            ZStack {
                Color(red: 0.05, green: 0.05, blue: 0.10)
                    .ignoresSafeArea()

                List {
                    Section("Gateway") {
                        HStack {
                            Text("Host")
                            Spacer()
                            Text(gateway.currentHost ?? "N/A")
                                .foregroundColor(.gray)
                        }
                        HStack {
                            Text("Port")
                            Spacer()
                            Text("\(gateway.currentPort)")
                                .foregroundColor(.gray)
                        }
                        HStack {
                            Text("Status")
                            Spacer()
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(gateway.isConnected ? Color.green : Color.red)
                                    .frame(width: 8, height: 8)
                                Text(gateway.isConnected ? "Connected" : "Disconnected")
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .listRowBackground(Color.white.opacity(0.05))

                    Section("Actions") {
                        Button("Disconnect") {
                            gateway.disconnect()
                            dismiss()
                        }
                        .foregroundColor(.red)
                    }
                    .listRowBackground(Color.white.opacity(0.05))

                    Section("About") {
                        HStack {
                            Text("Version")
                            Spacer()
                            Text("1.0.0")
                                .foregroundColor(.gray)
                        }
                        Link("OpenClaw Website", destination: URL(string: "https://openclaw.ai")!)
                        Link("GitHub", destination: URL(string: "https://github.com/openclaw/openclaw")!)
                    }
                    .listRowBackground(Color.white.opacity(0.05))
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.orange)
                }
            }
        }
    }
}
