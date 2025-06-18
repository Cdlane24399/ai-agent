//
//  ChatHeaderView.swift
//  Ai-Agent
//
//  Created by Chris Lane on 6/18/25.
//

import SwiftUI
import AppKit

struct ChatHeaderView: View {
    @EnvironmentObject var settingsManager: SettingsManager
    @EnvironmentObject var chatManager: ChatManager
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        HStack(spacing: 20) {
            // Model selector with modern styling
            ModelSelectorView()
            
            Spacer()
            
            // Controls with modern styling
            HStack(spacing: 16) {
                // Web search toggle with modern design
                Toggle(isOn: $settingsManager.useWebSearch) {
                    HStack(spacing: 6) {
                        Image(systemName: "globe")
                            .font(.system(size: 14, weight: .medium))
                        Text("Web Search")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundColor(
                        settingsManager.useWebSearch ? 
                        themeManager.currentTheme.colors.accent : 
                        themeManager.currentTheme.colors.secondaryText
                    )
                }
                .toggleStyle(.checkbox)
                .help("Enable web search for responses")
                
                // Divider
                Rectangle()
                    .fill(themeManager.currentTheme.colors.primaryBorder)
                    .frame(width: 1, height: 24)
                
                // Stop/Generate button
                if chatManager.isLoading {
                    Button(action: chatManager.stopGenerating) {
                        HStack(spacing: 6) {
                            Image(systemName: "stop.circle.fill")
                                .font(.system(size: 16, weight: .medium))
                            Text("Stop")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .foregroundColor(themeManager.currentTheme.colors.error)
                    }
                    .modernButton(style: .ghost, size: .small)
                }
                
                // Settings button
                Button(action: { appState.showSettings = true }) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(themeManager.currentTheme.colors.secondaryText)
                }
                .modernButton(style: .ghost, size: .small)
                .keyboardShortcut(",", modifiers: .command)
            }
        }
        .padding(.horizontal, 32)
        .padding(.vertical, 16)
        .themedBackground(.primary)
        .overlay(
            Rectangle()
                .fill(themeManager.currentTheme.colors.primaryBorder.opacity(0.3))
                .frame(height: 1),
            alignment: .bottom
        )
    }
}

struct ModelSelectorView: View {
    @EnvironmentObject var settingsManager: SettingsManager
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        HStack(spacing: 16) {
            // AI Brain icon with glow
            ZStack {
                Circle()
                    .fill(themeManager.currentTheme.colors.accent.opacity(0.15))
                    .frame(width: 32, height: 32)
                
                Image(systemName: "brain.filled.head.profile")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(themeManager.currentTheme.colors.accent)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("AI Model")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(themeManager.currentTheme.colors.secondaryText)
                
                Menu {
                    ForEach(OpenAIModel.allCases, id: \.self) { model in
                        Button(action: {
                            settingsManager.openAISettings.model = model
                            settingsManager.saveSettings()
                        }) {
                            HStack(spacing: 12) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(model.displayName)
                                        .font(.system(size: 15, weight: .semibold))
                                    Text(model.description)
                                        .font(.system(size: 13))
                                        .foregroundColor(themeManager.currentTheme.colors.secondaryText)
                                }
                                
                                Spacer()
                                
                                if model == settingsManager.openAISettings.model {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(themeManager.currentTheme.colors.accent)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                } label: {
                    HStack(spacing: 8) {
                        Text(settingsManager.openAISettings.model.displayName)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(themeManager.currentTheme.colors.primaryText)
                        
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(themeManager.currentTheme.colors.secondaryText)
                    }
                }
                .menuStyle(.borderlessButton)
            }
            
            // API Status indicator with modern design
            HStack(spacing: 8) {
                Circle()
                    .fill(
                        settingsManager.isConfigured ? 
                        themeManager.currentTheme.colors.success : 
                        themeManager.currentTheme.colors.error
                    )
                    .frame(width: 8, height: 8)
                    .overlay(
                        Circle()
                            .stroke(
                                settingsManager.isConfigured ? 
                                themeManager.currentTheme.colors.success.opacity(0.3) : 
                                themeManager.currentTheme.colors.error.opacity(0.3),
                                lineWidth: 4
                            )
                            .scaleEffect(1.8)
                    )
                
                Text(settingsManager.isConfigured ? "Connected" : "No API Key")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(
                        settingsManager.isConfigured ? 
                        themeManager.currentTheme.colors.success : 
                        themeManager.currentTheme.colors.error
                    )
            }
            .help(settingsManager.isConfigured ? "API key configured and ready" : "API key required in settings")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(themeManager.currentTheme.colors.tertiaryBackground.opacity(0.6))
        .cornerRadius(themeManager.currentTheme.cornerRadius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: themeManager.currentTheme.cornerRadius.lg)
                .stroke(themeManager.currentTheme.colors.primaryBorder.opacity(0.5), lineWidth: 1)
        )
    }
}

#Preview {
    ChatHeaderView()
        .environmentObject(SettingsManager())
        .environmentObject(ChatManager())
        .environmentObject(AppState())
        .frame(height: 60)
} 