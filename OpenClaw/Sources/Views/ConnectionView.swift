//
//  ConnectionView.swift
//  OpenClaw
//
//  Gateway discovery and manual connection UI.
//

import SwiftUI

// MARK: - Connection View

/// Displays discovered gateways via Bonjour and a manual connection form.
/// The animated lobster logo pulses while searching for gateways.
struct ConnectionView: View {
    @EnvironmentObject var gateway: GatewayManager
    @State private var host: String = ""
    @State private var port: String = "18789"
    @State private var isManualMode = false
    @State private var showingError = false
    @State private var pulseAnimation = false

    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.05, green: 0.05, blue: 0.12),
                        Color(red: 0.08, green: 0.02, blue: 0.15),
                        Color(red: 0.02, green: 0.02, blue: 0.08)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 32) {
                        Spacer().frame(height: 40)

                        // MARK: Logo & Title
                        logoSection

                        // MARK: Discovery Status
                        discoverySection

                        // MARK: Manual Connection
                        manualConnectionSection

                        // MARK: Connecting Indicator
                        if gateway.isConnecting {
                            connectingIndicator
                        }

                        Spacer()
                    }
                }
            }
            .navigationBarHidden(true)
        }
        .alert("Connection Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(gateway.lastError ?? "Unknown error")
        }
        .onChange(of: gateway.lastError) { error in
            showingError = error != nil
        }
        .onAppear {
            gateway.startDiscovery()
        }
    }

    // MARK: - Subviews

    private var logoSection: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [
                                Color.orange.opacity(0.3),
                                Color.clear
                            ]),
                            center: .center,
                            startRadius: 20,
                            endRadius: 80
                        )
                    )
                    .frame(width: 160, height: 160)
                    .scaleEffect(pulseAnimation ? 1.1 : 1.0)

                Text("🦞")
                    .font(.system(size: 72))
            }
            .onAppear {
                withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                    pulseAnimation = true
                }
            }

            Text("OpenClaw")
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.orange, .red],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )

            Text("Personal AI Assistant")
                .font(.subheadline)
                .foregroundColor(.gray)
        }
    }

    private var discoverySection: some View {
        VStack(spacing: 12) {
            if gateway.isSearching {
                HStack(spacing: 8) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .orange))
                        .scaleEffect(0.8)
                    Text("Searching for gateways...")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Color.white.opacity(0.05))
                .cornerRadius(20)
            }

            // Discovered gateways list
            if !gateway.discoveredGateways.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("DISCOVERED GATEWAYS")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundColor(.gray)
                        .padding(.horizontal, 4)

                    ForEach(gateway.discoveredGateways) { gw in
                        Button {
                            gateway.connect(to: gw)
                        } label: {
                            HStack {
                                Image(systemName: "network")
                                    .foregroundColor(.orange)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(gw.name)
                                        .font(.body)
                                        .fontWeight(.medium)
                                        .foregroundColor(.white)
                                    Text("\(gw.host):\(gw.port)")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.gray)
                                    .font(.caption)
                            }
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white.opacity(0.06))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                                    )
                            )
                        }
                    }
                }
                .padding(.horizontal, 24)
            }
        }
    }

    private var manualConnectionSection: some View {
        VStack(spacing: 16) {
            Button {
                withAnimation(.spring(response: 0.3)) {
                    isManualMode.toggle()
                }
            } label: {
                HStack {
                    Image(systemName: "keyboard")
                    Text("Manual Connection")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Spacer()
                    Image(systemName: isManualMode ? "chevron.up" : "chevron.down")
                        .font(.caption)
                }
                .foregroundColor(.white.opacity(0.8))
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.06))
                )
            }

            if isManualMode {
                VStack(spacing: 12) {
                    TextField("Gateway Host (IP or hostname)", text: $host)
                        .textFieldStyle(DarkTextFieldStyle())
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.URL)

                    TextField("Port", text: $port)
                        .textFieldStyle(DarkTextFieldStyle())
                        .keyboardType(.numberPad)

                    Button {
                        let p = Int(port) ?? 18789
                        let gw = DiscoveredGateway(
                            id: UUID().uuidString,
                            name: host,
                            host: host,
                            port: p
                        )
                        gateway.connect(to: gw)
                    } label: {
                        HStack {
                            Image(systemName: "bolt.fill")
                            Text("Connect")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            LinearGradient(
                                colors: [.orange, .red],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(12)
                    }
                    .disabled(host.isEmpty)
                    .opacity(host.isEmpty ? 0.5 : 1.0)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(.horizontal, 24)
    }

    private var connectingIndicator: some View {
        VStack(spacing: 12) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .orange))
            Text("Connecting to gateway...")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding(.vertical, 20)
    }
}

// MARK: - Dark Text Field Style

/// A custom `TextFieldStyle` with semi-transparent dark background
/// to match the app's dark theme.
struct DarkTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(14)
            .background(Color.white.opacity(0.06))
            .cornerRadius(10)
            .foregroundColor(.white)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
    }
}
