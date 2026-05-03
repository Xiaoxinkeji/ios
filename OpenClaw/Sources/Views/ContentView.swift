//
//  ContentView.swift
//  OpenClaw
//
//  Root view that switches between connection and chat screens.
//

import SwiftUI

/// Root navigation view — shows `ConnectionView` when disconnected,
/// transitions to `ChatView` once the gateway WebSocket is live.
struct ContentView: View {
    @EnvironmentObject var gateway: GatewayManager
    @EnvironmentObject var chatVM: ChatViewModel

    var body: some View {
        Group {
            if gateway.isConnected {
                ChatView()
            } else {
                ConnectionView()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: gateway.isConnected)
    }
}
