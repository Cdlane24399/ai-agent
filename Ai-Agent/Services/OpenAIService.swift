//
//  OpenAIService.swift
//  Ai-Agent
//
//  Created by Chris Lane on 6/18/25.
//

import Foundation

class OpenAIService {
    private let baseURL = "https://api.openai.com/v1"
    private let session = URLSession.shared
    
    struct StreamChunk {
        let content: String
        let sources: [WebSearchSource]?
        let status: String?
        let isComplete: Bool
    }
    
    struct OpenAIMessage: Codable {
        let role: String
        let content: OpenAIContent
    }
    
    enum OpenAIContent: Codable {
        case text(String)
        case multimodal([OpenAIContentPart])
        
        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            if let text = try? container.decode(String.self) {
                self = .text(text)
            } else {
                let parts = try container.decode([OpenAIContentPart].self)
                self = .multimodal(parts)
            }
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            switch self {
            case .text(let text):
                try container.encode(text)
            case .multimodal(let parts):
                try container.encode(parts)
            }
        }
    }
    
    struct OpenAIContentPart: Codable {
        let type: String
        let text: String?
        let image_url: OpenAIImageURL?
    }
    
    struct OpenAIImageURL: Codable {
        let url: String
    }
    
    struct ChatCompletionRequest: Codable {
        let model: String
        let messages: [OpenAIMessage]
        let temperature: Double
        let max_tokens: Int
        let stream: Bool
    }
    
    struct ChatCompletionResponse: Codable {
        let choices: [Choice]
        
        struct Choice: Codable {
            let delta: Delta
            
            struct Delta: Codable {
                let content: String?
            }
        }
    }
    
    func streamCompletion(
        messages: ArraySlice<ChatMessage>,
        settings: OpenAISettings?
    ) async throws -> AsyncThrowingStream<StreamChunk, Error> {
        
        // Get settings from SettingsManager if not provided
        let actualSettings = settings ?? getSettings()
        
        guard !actualSettings.apiKey.isEmpty else {
            throw OpenAIError.missingApiKey
        }
        
        // Convert ChatMessage to OpenAI format
        let openAIMessages = messages.map { message -> OpenAIMessage in
            let content: OpenAIContent
            
            if let files = message.files, !files.isEmpty {
                // Multimodal content
                var parts: [OpenAIContentPart] = []
                
                // Add text content if present
                if !message.content.isEmpty {
                    parts.append(OpenAIContentPart(type: "text", text: message.content, image_url: nil))
                }
                
                // Add file content
                for file in files {
                    switch file.type {
                    case .image:
                        if let data = file.data {
                            let base64 = data.base64EncodedString()
                            let dataURL = "data:image/png;base64,\(base64)"
                            parts.append(OpenAIContentPart(
                                type: "image_url",
                                text: nil,
                                image_url: OpenAIImageURL(url: dataURL)
                            ))
                        }
                    case .code, .text, .other:
                        if let data = file.data, let text = String(data: data, encoding: .utf8) {
                            parts.append(OpenAIContentPart(
                                type: "text",
                                text: "[File: \(file.name)]\n```\n\(text)\n```",
                                image_url: nil
                            ))
                        }
                    }
                }
                
                content = .multimodal(parts)
            } else {
                // Simple text content
                content = .text(message.content)
            }
            
            return OpenAIMessage(role: message.role.rawValue, content: content)
        }
        
        let request = ChatCompletionRequest(
            model: actualSettings.model.rawValue,
            messages: openAIMessages,
            temperature: actualSettings.temperature,
            max_tokens: actualSettings.maxTokens,
            stream: true
        )
        
        guard let url = URL(string: "\(baseURL)/chat/completions") else {
            throw OpenAIError.invalidURL
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("Bearer \(actualSettings.apiKey)", forHTTPHeaderField: "Authorization")
        urlRequest.httpBody = try JSONEncoder().encode(request)
        
        let (asyncBytes, response) = try await session.bytes(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw OpenAIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw OpenAIError.apiError(httpResponse.statusCode)
        }
        
        return AsyncThrowingStream<StreamChunk, Error> { continuation in
            Task {
                do {
                    for try await line in asyncBytes.lines {
                        if line.hasPrefix("data: ") {
                            let data = String(line.dropFirst(6))
                            
                            if data == "[DONE]" {
                                continuation.yield(StreamChunk(content: "", sources: nil, status: nil, isComplete: true))
                                continuation.finish()
                                return
                            }
                            
                            if let jsonData = data.data(using: .utf8),
                               let response = try? JSONDecoder().decode(ChatCompletionResponse.self, from: jsonData),
                               let content = response.choices.first?.delta.content {
                                continuation.yield(StreamChunk(content: content, sources: nil, status: nil, isComplete: false))
                            }
                        }
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
    
    private func getSettings() -> OpenAISettings {
        // This would normally come from SettingsManager
        // For now, return default settings
        return OpenAISettings()
    }
}

enum OpenAIError: LocalizedError {
    case missingApiKey
    case invalidURL
    case invalidResponse
    case apiError(Int)
    
    var errorDescription: String? {
        switch self {
        case .missingApiKey:
            return "OpenAI API key is missing. Please configure it in Settings."
        case .invalidURL:
            return "Invalid API URL"
        case .invalidResponse:
            return "Invalid response from OpenAI API"
        case .apiError(let code):
            return "OpenAI API error: \(code)"
        }
    }
} 