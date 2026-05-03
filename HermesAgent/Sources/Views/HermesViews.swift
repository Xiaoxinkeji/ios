//
//  HermesViews.swift
//  HermesAgent
//
//  All UI views: content router, connect screen, chat, settings, and components.
//

import SwiftUI

struct HermesContentView: View {
    @EnvironmentObject var agent: HermesAgentManager
    @EnvironmentObject var chatVM: HermesChatViewModel

    var body: some View {
        Group {
            if agent.isConnected {
                HermesChatView()
            } else {
                HermesConnectView()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: agent.isConnected)
        .onAppear {
            agent.tryAutoConnect()
        }
    }
}

// MARK: - Connect View

struct HermesConnectView: View {
    @EnvironmentObject var agent: HermesAgentManager
    @State private var serverURL = ""
    @State private var showingError = false
    @State private var glowAmount: CGFloat = 0.4

    var body: some View {
        ZStack {
            // Deep purple/indigo background
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.06, green: 0.04, blue: 0.14),
                    Color(red: 0.03, green: 0.02, blue: 0.10),
                    Color(red: 0.08, green: 0.04, blue: 0.16)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 36) {
                    Spacer().frame(height: 60)

                    // Logo
                    VStack(spacing: 20) {
                        ZStack {
                            Circle()
                                .fill(
                                    RadialGradient(
                                        gradient: Gradient(colors: [
                                            Color(red: 0.55, green: 0.35, blue: 1.0).opacity(glowAmount),
                                            Color.clear
                                        ]),
                                        center: .center,
                                        startRadius: 20,
                                        endRadius: 90
                                    )
                                )
                                .frame(width: 180, height: 180)

                            Text("⚡")
                                .font(.system(size: 72))
                        }
                        .onAppear {
                            withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
                                glowAmount = 0.7
                            }
                        }

                        Text("Hermes Agent")
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.65, green: 0.50, blue: 1.0),
                                        Color(red: 0.45, green: 0.30, blue: 0.95)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )

                        Text("The Agent That Grows With You")
                            .font(.subheadline)
                            .foregroundColor(.gray)

                        Text("by Nous Research")
                            .font(.caption)
                            .foregroundColor(.gray.opacity(0.6))
                    }

                    // Connection form
                    VStack(spacing: 16) {
                        Text("CONNECT TO YOUR GATEWAY")
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundColor(.gray)

                        TextField("Gateway URL (e.g. 192.168.1.100:8080)", text: $serverURL)
                            .padding(14)
                            .background(Color.white.opacity(0.06))
                            .cornerRadius(12)
                            .foregroundColor(.white)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.purple.opacity(0.2), lineWidth: 1)
                            )
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .keyboardType(.URL)

                        Button {
                            agent.connect(url: serverURL)
                        } label: {
                            HStack {
                                if agent.isConnecting {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                } else {
                                    Image(systemName: "bolt.fill")
                                }
                                Text(agent.isConnecting ? "Connecting..." : "Connect")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.55, green: 0.35, blue: 1.0),
                                        Color(red: 0.40, green: 0.20, blue: 0.85)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(12)
                        }
                        .disabled(serverURL.isEmpty || agent.isConnecting)
                        .opacity(serverURL.isEmpty ? 0.5 : 1.0)
                    }
                    .padding(.horizontal, 28)

                    // Features
                    VStack(spacing: 12) {
                        FeatureRow(icon: "brain", text: "Persistent memory & auto-generated skills")
                        FeatureRow(icon: "message.fill", text: "Telegram, Discord, Slack, Signal & more")
                        FeatureRow(icon: "clock.fill", text: "Cron scheduling for automated tasks")
                        FeatureRow(icon: "cube.fill", text: "Isolated subagents & sandboxing")
                    }
                    .padding(.horizontal, 28)

                    Spacer()
                }
            }
        }
        .alert("Connection Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(agent.lastError ?? "Unknown error")
        }
        .onChange(of: agent.lastError) { error in
            showingError = error != nil
        }
        .onAppear {
            serverURL = UserDefaults.standard.string(forKey: "hermes_server_url") ?? ""
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(Color(red: 0.6, green: 0.45, blue: 1.0))
                .font(.body)
                .frame(width: 24)
            Text(text)
                .font(.caption)
                .foregroundColor(.gray)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color.white.opacity(0.03))
        .cornerRadius(10)
    }
}

// MARK: - Chat View

struct HermesChatView: View {
    @EnvironmentObject var agent: HermesAgentManager
    @EnvironmentObject var chatVM: HermesChatViewModel
    @State private var messageText = ""
    @State private var showSettings = false
    @FocusState private var isInputFocused: Bool

    var body: some View {
        NavigationView {
            ZStack {
                Color(red: 0.04, green: 0.03, blue: 0.09)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Messages
                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(chatVM.messages) { msg in
                                    HermesMessageBubble(message: msg)
                                        .id(msg.id)
                                }

                                if chatVM.isTyping {
                                    HermesTypingView()
                                        .id("typing")
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                        }
                        .onChange(of: chatVM.messages.count) { _ in
                            withAnimation(.easeOut(duration: 0.2)) {
                                if let last = chatVM.messages.last {
                                    proxy.scrollTo(last.id, anchor: .bottom)
                                }
                            }
                        }
                    }

                    // Quick commands
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            QuickCommandButton(text: "/new") {
                                chatVM.sendMessage("/new", via: agent)
                            }
                            QuickCommandButton(text: "/model") {
                                chatVM.sendMessage("/model", via: agent)
                            }
                            QuickCommandButton(text: "/skills") {
                                chatVM.sendMessage("/skills", via: agent)
                            }
                            QuickCommandButton(text: "/usage") {
                                chatVM.sendMessage("/usage", via: agent)
                            }
                            QuickCommandButton(text: "/insights") {
                                chatVM.sendMessage("/insights", via: agent)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                    }
                    .background(Color(red: 0.06, green: 0.04, blue: 0.12))

                    // Input
                    hermesInputBar
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    VStack(spacing: 2) {
                        Text("⚡ Hermes Agent")
                            .font(.headline)
                            .foregroundColor(.white)
                        HStack(spacing: 4) {
                            Circle()
                                .fill(statusColor)
                                .frame(width: 6, height: 6)
                            Text(agent.agentStatus.rawValue)
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
                            .foregroundColor(Color(red: 0.6, green: 0.45, blue: 1.0))
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                HermesSettingsView()
            }
        }
    }

    private var statusColor: Color {
        switch agent.agentStatus {
        case .connected: return .green
        case .chatting: return .cyan
        case .connecting: return .yellow
        case .disconnected: return .red
        }
    }

    private var hermesInputBar: some View {
        HStack(spacing: 12) {
            TextField("Message Hermes...", text: $messageText, axis: .vertical)
                .lineLimit(1...5)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color.white.opacity(0.06))
                .cornerRadius(20)
                .foregroundColor(.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.purple.opacity(0.15), lineWidth: 1)
                )
                .focused($isInputFocused)

            Button {
                let text = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !text.isEmpty else { return }
                messageText = ""
                chatVM.sendMessage(text, via: agent)
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(
                        messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                        ? AnyShapeStyle(Color.gray)
                        : AnyShapeStyle(LinearGradient(
                            colors: [Color(red: 0.6, green: 0.45, blue: 1.0), Color(red: 0.4, green: 0.2, blue: 0.85)],
                            startPoint: .top, endPoint: .bottom
                        ))
                    )
            }
            .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(red: 0.06, green: 0.04, blue: 0.12))
    }
}

struct HermesMessageBubble: View {
    let message: HermesMessage

    var body: some View {
        HStack {
            if message.isUser { Spacer(minLength: 60) }

            VStack(alignment: message.isUser ? .trailing : .leading, spacing: 4) {
                Text(message.content + (message.isStreaming ? "▊" : ""))
                    .font(.body)
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        Group {
                            if message.isUser {
                                LinearGradient(
                                    colors: [Color(red: 0.55, green: 0.35, blue: 1.0), Color(red: 0.4, green: 0.2, blue: 0.85)],
                                    startPoint: .topLeading, endPoint: .bottomTrailing
                                )
                            } else {
                                Color.white.opacity(0.08)
                            }
                        }
                    )
                    .cornerRadius(18)

                Text(message.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundColor(.gray.opacity(0.5))
            }

            if !message.isUser { Spacer(minLength: 60) }
        }
    }
}

struct HermesTypingView: View {
    @State private var dots = [false, false, false]

    var body: some View {
        HStack {
            HStack(spacing: 5) {
                ForEach(0..<3) { i in
                    Circle()
                        .fill(Color(red: 0.6, green: 0.45, blue: 1.0).opacity(0.7))
                        .frame(width: 8, height: 8)
                        .offset(y: dots[i] ? -5 : 0)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Color.white.opacity(0.06))
            .cornerRadius(18)
            .onAppear {
                for i in 0..<3 {
                    withAnimation(.easeInOut(duration: 0.5).repeatForever().delay(Double(i) * 0.15)) {
                        dots[i] = true
                    }
                }
            }
            Spacer()
        }
    }
}

struct QuickCommandButton: View {
    let text: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(text)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(Color(red: 0.6, green: 0.45, blue: 1.0))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.white.opacity(0.05))
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.purple.opacity(0.2), lineWidth: 1)
                )
        }
    }
}

struct HermesSettingsView: View {
    @EnvironmentObject var agent: HermesAgentManager
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            ZStack {
                Color(red: 0.04, green: 0.03, blue: 0.09)
                    .ignoresSafeArea()

                List {
                    Section("Server") {
                        HStack {
                            Text("URL")
                            Spacer()
                            Text(agent.serverURL)
                                .foregroundColor(.gray)
                                .lineLimit(1)
                        }
                        HStack {
                            Text("Status")
                            Spacer()
                            Text(agent.agentStatus.rawValue)
                                .foregroundColor(.gray)
                        }
                    }
                    .listRowBackground(Color.white.opacity(0.05))

                    Section("Actions") {
                        Button("Disconnect") {
                            agent.disconnect()
                            dismiss()
                        }
                        .foregroundColor(.red)
                    }
                    .listRowBackground(Color.white.opacity(0.05))

                    Section("About") {
                        HStack {
                            Text("Version")
                            Spacer()
                            Text("1.0.0").foregroundColor(.gray)
                        }
                        Link("Hermes Agent Website", destination: URL(string: "https://hermes-agent.nousresearch.com")!)
                        Link("Nous Research", destination: URL(string: "https://nousresearch.com")!)
                        Link("GitHub", destination: URL(string: "https://github.com/NousResearch/hermes-agent")!)
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
                        .foregroundColor(Color(red: 0.6, green: 0.45, blue: 1.0))
                }
            }
        }
    }
}
