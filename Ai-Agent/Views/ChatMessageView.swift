//
//  ChatMessageView.swift
//  Ai-Agent
//
//  Created by Chris Lane on 6/18/25.
//

import SwiftUI

struct ChatMessageView: View {
    let message: ChatMessage
    let isStreaming: Bool
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Avatar
            MessageAvatar(role: message.role)
            
            // Content
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack {
                    Text(message.role.displayName)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(message.role == .user ? .accentColor : .primary)
                    
                    Spacer()
                    
                    Text(formatTimestamp(message.timestamp))
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                
                // Files preview (for user messages)
                if let files = message.files, !files.isEmpty {
                    FilesPreview(files: files)
                }
                
                // Message content
                MessageContent(message: message, isStreaming: isStreaming)
                
                // Sources (for assistant messages with web search)
                if let sources = message.sources, !sources.isEmpty {
                    SourcesView(sources: sources)
                }
                
                // Actions
                MessageActions(message: message)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(message.role == .user ? Color.accentColor.opacity(0.05) : Color(NSColor.controlBackgroundColor).opacity(0.5))
        )
    }
    
    private func formatTimestamp(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct MessageAvatar: View {
    let role: ChatMessage.MessageRole
    
    var body: some View {
        Circle()
            .fill(role == .user ? Color.accentColor : Color.secondary)
            .frame(width: 32, height: 32)
            .overlay(
                Image(systemName: role == .user ? "person.fill" : "brain")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
            )
    }
}

struct MessageContent: View {
    let message: ChatMessage
    let isStreaming: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if message.content.isEmpty && isStreaming {
                // Loading state
                HStack(spacing: 8) {
                    ForEach(0..<3, id: \.self) { index in
                        Circle()
                            .fill(Color.secondary)
                            .frame(width: 6, height: 6)
                            .opacity(0.6)
                            .scaleEffect(0.8)
                            .animation(
                                Animation.easeInOut(duration: 0.6)
                                    .repeatForever(autoreverses: true)
                                    .delay(Double(index) * 0.2),
                                value: isStreaming
                            )
                    }
                    
                    if let status = message.status {
                        Text(status)
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                }
            } else {
                // Message text (markdown support to be added with MarkdownUI package)
                Text(message.content)
                    .font(.system(size: 15, design: .default))
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                // Streaming cursor
                if isStreaming && !message.content.isEmpty {
                    HStack {
                        Spacer()
                        Rectangle()
                            .fill(Color.accentColor)
                            .frame(width: 2, height: 16)
                            .opacity(0.8)
                            .animation(
                                Animation.easeInOut(duration: 0.8).repeatForever(autoreverses: true),
                                value: isStreaming
                            )
                    }
                }
            }
        }
    }
}

struct FilesPreview: View {
    let files: [UploadedFile]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(files) { file in
                    FilePreviewCard(file: file)
                }
            }
            .padding(.horizontal, 4)
        }
    }
}

struct FilePreviewCard: View {
    let file: UploadedFile
    
    var body: some View {
        VStack(spacing: 8) {
            // File icon or image preview
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(NSColor.controlBackgroundColor))
                .frame(width: 60, height: 60)
                .overlay(
                    Group {
                        if file.type == .image, let preview = file.preview,
                           let imageData = Data(base64Encoded: preview),
                           let nsImage = NSImage(data: imageData) {
                            Image(nsImage: nsImage)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .clipped()
                        } else {
                            Image(systemName: file.type.icon)
                                .font(.system(size: 24))
                                .foregroundColor(.accentColor)
                        }
                    }
                )
                .cornerRadius(8)
            
            // File name
            Text(file.name)
                .font(.system(size: 12))
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .frame(width: 80)
        }
    }
}

struct SourcesView: View {
    let sources: [WebSearchSource]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "globe")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                
                Text("Sources")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
            }
            
            VStack(spacing: 6) {
                ForEach(sources) { source in
                    SourceCard(source: source)
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(NSColor.controlBackgroundColor).opacity(0.3))
        )
    }
}

struct SourceCard: View {
    let source: WebSearchSource
    
    var body: some View {
        Button(action: {
            if let url = URL(string: source.url) {
                NSWorkspace.shared.open(url)
            }
        }) {
            HStack(spacing: 8) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(source.title)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    if !source.snippet.isEmpty {
                        Text(source.snippet)
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                    
                    Text(source.url)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color(NSColor.controlBackgroundColor).opacity(0.5))
            )
        }
        .buttonStyle(.plain)
    }
}

struct MessageActions: View {
    let message: ChatMessage
    
    var body: some View {
        HStack(spacing: 12) {
            Button(action: {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(message.content, forType: .string)
            }) {
                Image(systemName: "doc.on.doc")
                    .font(.system(size: 14))
            }
            .buttonStyle(.borderless)
            .help("Copy message")
            
            Spacer()
        }
        .opacity(0.6)
    }
}

#Preview {
    VStack(spacing: 16) {
        ChatMessageView(
            message: ChatMessage(
                content: "Hello! How can I help you today?",
                role: .assistant
            ),
            isStreaming: false
        )
        
        ChatMessageView(
            message: ChatMessage(
                content: "Can you analyze this code for me?",
                role: .user
            ),
            isStreaming: false
        )
    }
    .padding()
    .frame(width: 600)
} 