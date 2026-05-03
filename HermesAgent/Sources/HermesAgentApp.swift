//
//  HermesAgentApp.swift
//  HermesAgent
//
//  iOS companion client for Hermes Agent by Nous Research.
//

import SwiftUI

@main
struct HermesAgentApp: App {
    @StateObject private var agentManager = HermesAgentManager()
    @StateObject private var chatVM = HermesChatViewModel()

    var body: some Scene {
        WindowGroup {
            HermesContentView()
                .environmentObject(agentManager)
                .environmentObject(chatVM)
                .preferredColorScheme(.dark)
        }
    }
}
