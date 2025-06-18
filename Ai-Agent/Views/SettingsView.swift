//
//  SettingsView.swift
//  Ai-Agent
//
//  Created by Chris Lane on 6/18/25.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var settingsManager: SettingsManager
    @EnvironmentObject var appState: AppState
    @State private var apiKey = ""
    @State private var showAPIKey = false
    
    var body: some View {
        NavigationStack {
            Form {
                // OpenAI Settings
                Section("OpenAI Configuration") {
                    VStack(alignment: .leading, spacing: 12) {
                        // API Key
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text("API Key")
                                    .font(.headline)
                                
                                Spacer()
                                
                                Button(showAPIKey ? "Hide" : "Show") {
                                    showAPIKey.toggle()
                                }
                                .font(.caption)
                            }
                            
                            HStack {
                                if showAPIKey {
                                    TextField("sk-...", text: $apiKey)
                                } else {
                                    SecureField("sk-...", text: $apiKey)
                                }
                                
                                Button("Paste") {
                                    if let clipboard = NSPasteboard.general.string(forType: .string) {
                                        apiKey = clipboard
                                    }
                                }
                                .font(.caption)
                            }
                            
                            Text("Get your API key from OpenAI's website")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            HStack {
                                Circle()
                                    .fill(settingsManager.validateApiKey(apiKey) ? .green : .red)
                                    .frame(width: 8, height: 8)
                                
                                Text(settingsManager.validateApiKey(apiKey) ? "Valid format" : "Invalid format")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Divider()
                        
                        // Model Selection
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Model")
                                .font(.headline)
                            
                            Picker("Model", selection: $settingsManager.openAISettings.model) {
                                ForEach(OpenAIModel.allCases, id: \.self) { model in
                                    VStack(alignment: .leading) {
                                        Text(model.displayName)
                                        Text(model.description)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    .tag(model)
                                }
                            }
                            .pickerStyle(.menu)
                        }
                        
                        Divider()
                        
                        // Temperature
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text("Temperature")
                                    .font(.headline)
                                Spacer()
                                Text(String(format: "%.1f", settingsManager.openAISettings.temperature))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Slider(
                                value: $settingsManager.openAISettings.temperature,
                                in: 0.0...2.0,
                                step: 0.1
                            )
                            
                            Text("Controls randomness: 0 is focused, 2 is very creative")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Divider()
                        
                        // Max Tokens
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text("Max Tokens")
                                    .font(.headline)
                                Spacer()
                                Text("\(settingsManager.openAISettings.maxTokens)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Slider(
                                value: Binding(
                                    get: { Double(settingsManager.openAISettings.maxTokens) },
                                    set: { settingsManager.openAISettings.maxTokens = Int($0) }
                                ),
                                in: 100...8000,
                                step: 100
                            )
                            
                            Text("Maximum tokens in the response")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // App Settings
                Section("App Settings") {
                    Toggle("Auto-generate conversation titles", isOn: $settingsManager.autoGenerateTitle)
                    Toggle("Enable web search", isOn: $settingsManager.useWebSearch)
                    Toggle("Save conversations", isOn: $settingsManager.saveConversations)
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Theme")
                            .font(.headline)
                        
                        Picker("Theme", selection: $appState.currentTheme) {
                            ForEach(AppState.AppTheme.allCases, id: \.self) { theme in
                                Text(theme.displayName).tag(theme)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                }
                
                // About
                Section("About") {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "brain.head.profile")
                                .font(.system(size: 32))
                                .foregroundColor(.accentColor)
                            
                            VStack(alignment: .leading) {
                                Text("AI Agent")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                
                                Text("Version 1.0.0")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Text("A native macOS AI assistant with modern design and powerful capabilities.")
                            .font(.body)
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 16) {
                            Button("Reset Settings") {
                                resetSettings()
                            }
                            .foregroundColor(.red)
                            
                            Spacer()
                            
                            Button("Privacy Policy") {
                                // Open privacy policy
                            }
                            
                            Button("Support") {
                                // Open support
                            }
                        }
                    }
                }
            }
            .formStyle(.grouped)
            .navigationTitle("Settings")

            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        saveSettings()
                        appState.showSettings = false
                    }
                    .keyboardShortcut(.return, modifiers: .command)
                }
                
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        loadSettings()
                        appState.showSettings = false
                    }
                    .keyboardShortcut(.escape)
                }
            }
        }
        .frame(minWidth: 500, minHeight: 600)
        .onAppear {
            loadSettings()
        }
    }
    
    private func loadSettings() {
        apiKey = settingsManager.openAISettings.apiKey
    }
    
    private func saveSettings() {
        settingsManager.openAISettings.apiKey = apiKey
        settingsManager.saveSettings()
    }
    
    private func resetSettings() {
        let alert = NSAlert()
        alert.messageText = "Reset Settings"
        alert.informativeText = "This will reset all settings to default values. This action cannot be undone."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Reset")
        alert.addButton(withTitle: "Cancel")
        
        if alert.runModal() == .alertFirstButtonReturn {
            settingsManager.resetSettings()
            loadSettings()
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(SettingsManager())
        .environmentObject(AppState())
} 