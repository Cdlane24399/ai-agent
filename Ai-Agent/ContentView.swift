//
//  ContentView.swift
//  Ai-Agent
//
//  Created by Chris Lane on 6/18/25.
//

import SwiftUI
import UniformTypeIdentifiers
import Foundation

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var chatManager: ChatManager
    @EnvironmentObject var settingsManager: SettingsManager
    @EnvironmentObject var themeManager: ThemeManager
    @State private var showSidebar = false
    @State private var isDragTargeted = false
    
    var body: some View {
        NavigationSplitView {
            // Sidebar
            ChatSidebarView(showSidebar: $showSidebar)
                .navigationSplitViewColumnWidth(min: 260, ideal: 300, max: 400)
        } detail: {
            // Main chat interface
            VStack(spacing: 0) {
                // Header with model selector
                ChatHeaderView()
                    .padding(.top, 28) // Account for hidden title bar
                
                // Chat content
                if appState.showSettings {
                    SettingsView()
                } else {
                    ChatInterfaceView()
                }
            }
            .themedBackground(BackgroundLevel.primary)
        }
        .navigationSplitViewStyle(.balanced)
        .themedBackground(BackgroundLevel.secondary)
        .sheet(isPresented: $appState.showSettings) {
            SettingsView()
                .environmentObject(settingsManager)
        }
        .onDrop(of: [UTType.fileURL.identifier, UTType.image.identifier], isTargeted: $isDragTargeted) { providers in
            return chatManager.handleDroppedFiles(providers)
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            // Handle app becoming active
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState())
        .environmentObject(ChatManager())
        .environmentObject(SettingsManager())
        .environmentObject(ThemeManager.shared)
}
