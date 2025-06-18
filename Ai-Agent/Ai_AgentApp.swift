//
//  Ai_AgentApp.swift
//  Ai-Agent
//
//  Created by Chris Lane on 6/18/25.
//

import SwiftUI

@main
struct Ai_AgentApp: App {
    @StateObject private var appState = AppState()
    @StateObject private var chatManager = ChatManager()
    @StateObject private var settingsManager = SettingsManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .environmentObject(chatManager)
                .environmentObject(settingsManager)
                .environmentObject(ThemeManager.shared)
                .frame(minWidth: 800, minHeight: 600)
                .onAppear {
                    setupWindow()
                }
        }
        .windowStyle(.hiddenTitleBar)
        .windowToolbarStyle(.unified)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("New Chat") {
                    chatManager.startNewChat()
                }
                .keyboardShortcut("n", modifiers: .command)
            }
            
            CommandGroup(after: .newItem) {
                Divider()
                
                Button("Import Chat...") {
                    chatManager.importChat()
                }
                .keyboardShortcut("o", modifiers: .command)
                
                Button("Export Chat...") {
                    chatManager.exportCurrentChat()
                }
                .keyboardShortcut("s", modifiers: .command)
            }
            
            CommandGroup(replacing: .appSettings) {
                Button("Settings...") {
                    appState.showSettings = true
                }
                .keyboardShortcut(",", modifiers: .command)
            }
        }
        
        Settings {
            SettingsView()
                .environmentObject(settingsManager)
        }
    }
    
    private func setupWindow() {
        guard let window = NSApplication.shared.windows.first else { return }
        
        // Modern macOS window appearance
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.styleMask.insert(.fullSizeContentView)
        
        // Set minimum window size for better UX
        window.minSize = NSSize(width: 800, height: 600)
        
        // Enable window animations
        window.animationBehavior = .documentWindow
    }
}
