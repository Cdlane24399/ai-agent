//
//  ChatManager.swift
//  Ai-Agent
//
//  Created by Chris Lane on 6/18/25.
//

import Foundation
import SwiftUI
import Combine
import UniformTypeIdentifiers

class ChatManager: ObservableObject {
    @Published var currentSession: ChatSession = ChatSession()
    @Published var sessions: [ChatSession] = []
    @Published var isLoading = false
    @Published var streamingMessageId: String?
    
    private let openAIService = OpenAIService()
    private let fileManager = FileManager.default
    private var streamingTask: Task<Void, Never>?
    
    init() {
        loadSessions()
    }
    
    // MARK: - Session Management
    
    func startNewChat() {
        // Save current session if it has messages
        if !currentSession.messages.isEmpty {
            saveCurrentSession()
        }
        
        currentSession = ChatSession()
        objectWillChange.send()
    }
    
    func loadSession(_ session: ChatSession) {
        // Save current session first
        if !currentSession.messages.isEmpty {
            saveCurrentSession()
        }
        
        currentSession = session
        objectWillChange.send()
    }
    
    func deleteSession(_ session: ChatSession) {
        sessions.removeAll { $0.id == session.id }
        saveSessions()
        
        // If we deleted the current session, start a new one
        if currentSession.id == session.id {
            startNewChat()
        }
    }
    
    private func saveCurrentSession() {
        if let index = sessions.firstIndex(where: { $0.id == currentSession.id }) {
            sessions[index] = currentSession
        } else if !currentSession.messages.isEmpty {
            sessions.insert(currentSession, at: 0)
        }
        saveSessions()
    }
    
    // MARK: - Message Management
    
    func sendMessage(_ content: String, files: [UploadedFile] = []) {
        guard !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !files.isEmpty else {
            return
        }
        
        let userMessage = ChatMessage(
            content: content,
            role: .user,
            files: files.isEmpty ? nil : files
        )
        
        currentSession.addMessage(userMessage)
        objectWillChange.send()
        
        // Start AI response
        generateAIResponse()
    }
    
    private func generateAIResponse() {
        guard !isLoading else { return }
        
        isLoading = true
        
        // Create placeholder assistant message
        let assistantMessage = ChatMessage(
            content: "",
            role: .assistant
        )
        currentSession.addMessage(assistantMessage)
        streamingMessageId = assistantMessage.id
        objectWillChange.send()
        
        // Start streaming response
        streamingTask = Task {
            await streamAIResponse(messageId: assistantMessage.id)
        }
    }
    
    @MainActor
    private func streamAIResponse(messageId: String) async {
        defer {
            isLoading = false
            streamingMessageId = nil
            saveCurrentSession()
        }
        
        do {
            let stream = try await openAIService.streamCompletion(
                messages: currentSession.messages.dropLast(), // Don't include the empty assistant message
                settings: nil // Will be provided by SettingsManager
            )
            
            var accumulatedContent = ""
            
            for try await chunk in stream {
                guard !Task.isCancelled else { break }
                
                accumulatedContent += chunk.content
                
                // Update the message
                if let index = currentSession.messages.firstIndex(where: { $0.id == messageId }) {
                    currentSession.messages[index].content = accumulatedContent
                    currentSession.messages[index].sources = chunk.sources
                    currentSession.messages[index].status = chunk.status
                    objectWillChange.send()
                }
            }
            
        } catch {
            // Handle error
            if let index = currentSession.messages.firstIndex(where: { $0.id == messageId }) {
                currentSession.messages[index].content = "Sorry, I encountered an error: \(error.localizedDescription)"
                objectWillChange.send()
            }
        }
    }
    
    func stopGenerating() {
        streamingTask?.cancel()
        streamingTask = nil
        isLoading = false
        streamingMessageId = nil
    }
    
    // MARK: - File Handling
    
    func handleDroppedFiles(_ providers: [NSItemProvider]) -> Bool {
        var uploadedFiles: [UploadedFile] = []
        let group = DispatchGroup()
        
        for provider in providers {
            group.enter()
            
            if provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
                provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { (item, error) in
                    defer { group.leave() }
                    
                    guard let url = item as? URL else { return }
                    
                    do {
                        let data = try Data(contentsOf: url)
                        let file = self.createUploadedFile(from: url, data: data)
                        uploadedFiles.append(file)
                    } catch {
                        print("Error reading file: \(error)")
                    }
                }
            } else if provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
                provider.loadItem(forTypeIdentifier: UTType.image.identifier, options: nil) { (item, error) in
                    defer { group.leave() }
                    
                    if let image = item as? NSImage,
                       let data = image.tiffRepresentation {
                        let file = UploadedFile(
                            name: "image.png",
                            type: .image,
                            size: Int64(data.count),
                            data: data
                        )
                        uploadedFiles.append(file)
                    }
                }
            }
        }
        
        group.notify(queue: .main) {
            if !uploadedFiles.isEmpty {
                let message = uploadedFiles.count == 1
                    ? "I've uploaded \(uploadedFiles[0].name). Please analyze it."
                    : "I've uploaded \(uploadedFiles.count) files. Please analyze them."
                
                self.sendMessage(message, files: uploadedFiles)
            }
        }
        
        return !uploadedFiles.isEmpty
    }
    
    private func createUploadedFile(from url: URL, data: Data) -> UploadedFile {
        let fileExtension = url.pathExtension.lowercased()
        let fileName = url.lastPathComponent
        
        let fileType: UploadedFile.FileType
        if ["jpg", "jpeg", "png", "gif", "bmp", "tiff"].contains(fileExtension) {
            fileType = .image
        } else if ["swift", "js", "ts", "py", "java", "cpp", "c", "h", "m", "json", "xml", "html", "css"].contains(fileExtension) {
            fileType = .code
        } else if ["txt", "md", "rtf", "doc", "docx", "pdf"].contains(fileExtension) {
            fileType = .text
        } else {
            fileType = .other
        }
        
        return UploadedFile(
            name: fileName,
            type: fileType,
            size: Int64(data.count),
            data: data
        )
    }
    
    // MARK: - Import/Export
    
    func importChat() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.json]
        panel.allowsMultipleSelection = false
        
        if panel.runModal() == .OK, let url = panel.url {
            do {
                let data = try Data(contentsOf: url)
                let session = try JSONDecoder().decode(ChatSession.self, from: data)
                sessions.insert(session, at: 0)
                saveSessions()
            } catch {
                print("Error importing chat: \(error)")
            }
        }
    }
    
    func exportCurrentChat() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.json]
        panel.nameFieldStringValue = "chat-\(currentSession.id).json"
        
        if panel.runModal() == .OK, let url = panel.url {
            do {
                let data = try JSONEncoder().encode(currentSession)
                try data.write(to: url)
            } catch {
                print("Error exporting chat: \(error)")
            }
        }
    }
    
    // MARK: - Persistence
    
    private func loadSessions() {
        guard let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return
        }
        
        let sessionsURL = documentsPath.appendingPathComponent("chat-sessions.json")
        
        guard fileManager.fileExists(atPath: sessionsURL.path),
              let data = try? Data(contentsOf: sessionsURL),
              let loadedSessions = try? JSONDecoder().decode([ChatSession].self, from: data) else {
            return
        }
        
        sessions = loadedSessions.sorted { $0.updatedAt > $1.updatedAt }
    }
    
    private func saveSessions() {
        guard let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return
        }
        
        let sessionsURL = documentsPath.appendingPathComponent("chat-sessions.json")
        
        do {
            let data = try JSONEncoder().encode(sessions)
            try data.write(to: sessionsURL)
        } catch {
            print("Error saving sessions: \(error)")
        }
    }
} 