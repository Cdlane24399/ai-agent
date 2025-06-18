//
//  SettingsManager.swift
//  Ai-Agent
//
//  Created by Chris Lane on 6/18/25.
//

import Foundation
import SwiftUI
import Combine
import Security

class SettingsManager: ObservableObject {
    @Published var openAISettings = OpenAISettings()
    @Published var autoGenerateTitle = true
    @Published var useWebSearch = false
    @Published var saveConversations = true
    
    private let keychain = KeychainHelper()
    private let userDefaults = UserDefaults.standard
    
    init() {
        loadSettings()
    }
    
    func loadSettings() {
        // Load OpenAI API key from keychain
        if let apiKey = keychain.get(service: "ai-agent", account: "openai-api-key") {
            openAISettings.apiKey = apiKey
        }
        
        // Load other settings from UserDefaults
        if let modelRaw = userDefaults.string(forKey: "OpenAI_Model"),
           let model = OpenAIModel(rawValue: modelRaw) {
            openAISettings.model = model
        }
        
        openAISettings.temperature = userDefaults.object(forKey: "OpenAI_Temperature") as? Double ?? 0.7
        openAISettings.maxTokens = userDefaults.object(forKey: "OpenAI_MaxTokens") as? Int ?? 4000
        openAISettings.webSearchEnabled = userDefaults.bool(forKey: "OpenAI_WebSearch")
        
        autoGenerateTitle = userDefaults.object(forKey: "AutoGenerateTitle") as? Bool ?? true
        useWebSearch = userDefaults.object(forKey: "UseWebSearch") as? Bool ?? false
        saveConversations = userDefaults.object(forKey: "SaveConversations") as? Bool ?? true
    }
    
    func saveSettings() {
        // Save API key to keychain
        if !openAISettings.apiKey.isEmpty {
            _ = keychain.set(openAISettings.apiKey, service: "ai-agent", account: "openai-api-key")
        }
        
        // Save other settings to UserDefaults
        userDefaults.set(openAISettings.model.rawValue, forKey: "OpenAI_Model")
        userDefaults.set(openAISettings.temperature, forKey: "OpenAI_Temperature")
        userDefaults.set(openAISettings.maxTokens, forKey: "OpenAI_MaxTokens")
        userDefaults.set(openAISettings.webSearchEnabled, forKey: "OpenAI_WebSearch")
        
        userDefaults.set(autoGenerateTitle, forKey: "AutoGenerateTitle")
        userDefaults.set(useWebSearch, forKey: "UseWebSearch")
        userDefaults.set(saveConversations, forKey: "SaveConversations")
    }
    
    func validateApiKey(_ key: String) -> Bool {
        return key.hasPrefix("sk-") && key.count > 20
    }
    
    var isConfigured: Bool {
        return validateApiKey(openAISettings.apiKey)
    }
    
    func resetSettings() {
        openAISettings = OpenAISettings()
        autoGenerateTitle = true
        useWebSearch = false
        saveConversations = true
        
        // Clear keychain
        _ = keychain.delete(service: "ai-agent", account: "openai-api-key")
        
        // Clear UserDefaults
        let keys = ["OpenAI_Model", "OpenAI_Temperature", "OpenAI_MaxTokens", "OpenAI_WebSearch",
                   "AutoGenerateTitle", "UseWebSearch", "SaveConversations"]
        keys.forEach { userDefaults.removeObject(forKey: $0) }
    }
}

// MARK: - Keychain Helper

class KeychainHelper {
    func set(_ value: String, service: String, account: String) -> Bool {
        let data = value.data(using: .utf8)!
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data
        ]
        
        // Delete any existing item
        SecItemDelete(query as CFDictionary)
        
        // Add the new item
        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    func get(service: String, account: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        
        if status == errSecSuccess {
            if let data = dataTypeRef as? Data {
                return String(data: data, encoding: .utf8)
            }
        }
        
        return nil
    }
    
    func delete(service: String, account: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess
    }
} 