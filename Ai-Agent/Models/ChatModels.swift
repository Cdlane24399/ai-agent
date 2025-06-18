//
//  ChatModels.swift
//  Ai-Agent
//
//  Created by Chris Lane on 6/18/25.
//

import Foundation
import SwiftUI

// MARK: - Message Models

struct ChatMessage: Identifiable, Codable {
    let id: String
    var content: String
    let role: MessageRole
    let timestamp: Date
    var files: [UploadedFile]?
    var sources: [WebSearchSource]?
    var isStreaming: Bool = false
    var status: String?
    
    enum MessageRole: String, Codable, CaseIterable {
        case user = "user"
        case assistant = "assistant"
        case system = "system"
        
        var displayName: String {
            switch self {
            case .user: return "You"
            case .assistant: return "AI"
            case .system: return "System"
            }
        }
    }
    
    init(id: String = UUID().uuidString, content: String, role: MessageRole, files: [UploadedFile]? = nil) {
        self.id = id
        self.content = content
        self.role = role
        self.timestamp = Date()
        self.files = files
    }
}

struct UploadedFile: Identifiable, Codable {
    let id: String
    let name: String
    let type: FileType
    let size: Int64
    let data: Data?
    let preview: String? // Base64 encoded preview for images
    
    enum FileType: String, Codable, CaseIterable {
        case image = "image"
        case code = "code"
        case text = "text"
        case other = "other"
        
        var icon: String {
            switch self {
            case .image: return "photo"
            case .code: return "chevron.left.forwardslash.chevron.right"
            case .text: return "doc.text"
            case .other: return "doc"
            }
        }
    }
    
    init(id: String = UUID().uuidString, name: String, type: FileType, size: Int64, data: Data? = nil) {
        self.id = id
        self.name = name
        self.type = type
        self.size = size
        self.data = data
        self.preview = nil
    }
}

struct WebSearchSource: Identifiable, Codable {
    let id: String
    let title: String
    let url: String
    let snippet: String
    
    init(id: String = UUID().uuidString, title: String, url: String, snippet: String) {
        self.id = id
        self.title = title
        self.url = url
        self.snippet = snippet
    }
}

// MARK: - Chat Session Models

struct ChatSession: Identifiable, Codable {
    let id: String
    var title: String
    var messages: [ChatMessage]
    let createdAt: Date
    var updatedAt: Date
    
    init(id: String = UUID().uuidString, title: String = "New Chat") {
        self.id = id
        self.title = title
        self.messages = []
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    mutating func addMessage(_ message: ChatMessage) {
        messages.append(message)
        updatedAt = Date()
        
        // Auto-generate title from first user message if still default
        if title == "New Chat", message.role == .user, !message.content.isEmpty {
            title = String(message.content.prefix(50)) + (message.content.count > 50 ? "..." : "")
        }
    }
    
    var lastMessage: ChatMessage? {
        messages.last
    }
    
    var messageCount: Int {
        messages.count
    }
}

// MARK: - API Models

struct OpenAISettings: Codable {
    var apiKey: String
    var model: OpenAIModel
    var temperature: Double
    var maxTokens: Int
    var webSearchEnabled: Bool
    
    init() {
        self.apiKey = ""
        self.model = .gpt4oMini
        self.temperature = 0.7
        self.maxTokens = 4000
        self.webSearchEnabled = false
    }
}

enum OpenAIModel: String, Codable, CaseIterable {
    case gpt4o = "gpt-4o"
    case gpt4oMini = "gpt-4o-mini"
    case gpt4Turbo = "gpt-4-turbo"
    case gpt35Turbo = "gpt-3.5-turbo"
    
    var displayName: String {
        switch self {
        case .gpt4o: return "GPT-4o"
        case .gpt4oMini: return "GPT-4o Mini"
        case .gpt4Turbo: return "GPT-4 Turbo"
        case .gpt35Turbo: return "GPT-3.5 Turbo"
        }
    }
    
    var description: String {
        switch self {
        case .gpt4o: return "Most capable model, supports vision"
        case .gpt4oMini: return "Faster and more affordable"
        case .gpt4Turbo: return "High-performance model"
        case .gpt35Turbo: return "Fast and reliable"
        }
    }
    
    var supportsVision: Bool {
        switch self {
        case .gpt4o, .gpt4Turbo: return true
        case .gpt4oMini, .gpt35Turbo: return false
        }
    }
} 