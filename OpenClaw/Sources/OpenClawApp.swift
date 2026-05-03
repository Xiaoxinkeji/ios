//
//  OpenClawApp.swift
//  OpenClaw
//
//  iOS companion client for openclaw.ai
//

import SwiftUI

@main
struct OpenClawApp: App {
    @StateObject private var gatewayManager = GatewayManager()
    @StateObject private var chatViewModel = ChatViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(gatewayManager)
                .environmentObject(chatViewModel)
                .preferredColorScheme(.dark)
        }
    }
}
