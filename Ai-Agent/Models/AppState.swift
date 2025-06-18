//
//  AppState.swift
//  Ai-Agent
//
//  Created by Chris Lane on 6/18/25.
//

import SwiftUI
import Combine
import AppKit

class AppState: ObservableObject {
    @Published var showSettings = false
    @Published var isLoading = false
    @Published var showWelcome = true
    @Published var sidebarVisible = false
    @Published var currentTheme: AppTheme = .auto
    
    // Window state
    @Published var windowFocused = true
    @Published var isFullscreen = false
    
    enum AppTheme: String, CaseIterable {
        case light = "light"
        case dark = "dark"
        case auto = "auto"
        
        var displayName: String {
            switch self {
            case .light: return "Light"
            case .dark: return "Dark"
            case .auto: return "Auto"
            }
        }
    }
    
    init() {
        // Load saved preferences
        loadPreferences()
        
        // Listen for system appearance changes
        NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { _ in
            self.updateForSystemAppearance()
        }
    }
    
    private func loadPreferences() {
        if let savedTheme = UserDefaults.standard.string(forKey: "AppTheme"),
           let theme = AppTheme(rawValue: savedTheme) {
            currentTheme = theme
        }
    }
    
    private func updateForSystemAppearance() {
        if currentTheme == .auto {
            // Trigger UI update for auto theme
            objectWillChange.send()
        }
    }
    
    func toggleSidebar() {
        withAnimation(.easeInOut(duration: 0.3)) {
            sidebarVisible.toggle()
        }
    }
    
    func setTheme(_ theme: AppTheme) {
        currentTheme = theme
        UserDefaults.standard.set(theme.rawValue, forKey: "AppTheme")
    }
} 