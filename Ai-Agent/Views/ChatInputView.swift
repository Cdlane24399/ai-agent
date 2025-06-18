//
//  ChatInputView.swift
//  Ai-Agent
//
//  Created by Chris Lane on 6/18/25.
//

import SwiftUI
import Combine
import UniformTypeIdentifiers

struct ChatInputView: View {
    @EnvironmentObject var chatManager: ChatManager
    @EnvironmentObject var settingsManager: SettingsManager
    @EnvironmentObject var themeManager: ThemeManager
    @State private var inputText = ""
    @State private var selectedFiles: [UploadedFile] = []
    @State private var isFilePickerPresented = false
    @State private var isDragOver = false
    @FocusState private var isInputFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Subtle top border for visual separation
            Rectangle()
                .fill(themeManager.currentTheme.colors.primaryBorder.opacity(0.3))
                .frame(height: 1)
            
            // File attachments preview
            if !selectedFiles.isEmpty {
                FileAttachmentsView(files: $selectedFiles)
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
            }
            
            // Input area with more compact sizing
            HStack(alignment: .bottom, spacing: 10) {
                // File picker button
                Button(action: { isFilePickerPresented = true }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(themeManager.currentTheme.colors.accent)
                }
                .buttonStyle(.plain)
                .help("Attach files")
                
                // Text input with more compact styling
                VStack(spacing: 4) {
                    ZStack(alignment: .topLeading) {
                        // Modern input background with subtle styling
                        RoundedRectangle(cornerRadius: themeManager.currentTheme.cornerRadius.lg)
                            .fill(themeManager.currentTheme.colors.surfaceBackground)
                            .overlay(
                                RoundedRectangle(cornerRadius: themeManager.currentTheme.cornerRadius.lg)
                                    .stroke(
                                        isDragOver ? themeManager.currentTheme.colors.accent :
                                        isInputFocused ? themeManager.currentTheme.colors.focusBorder :
                                        themeManager.currentTheme.colors.primaryBorder,
                                        lineWidth: isDragOver || isInputFocused ? 2 : 1
                                    )
                            )
                            .themedShadow(.small)
                        
                        // Text editor with more compact sizing
                        TextEditor(text: $inputText)
                            .focused($isInputFocused)
                            .font(.system(size: 14))
                            .scrollContentBackground(.hidden)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .frame(minHeight: 32, maxHeight: 60)
                            .overlay(
                                // Placeholder with better styling
                                Group {
                                    if inputText.isEmpty {
                                        HStack {
                                            Text("Ask me anything...")
                                                .foregroundColor(themeManager.currentTheme.colors.placeholderText)
                                                .font(.system(size: 14))
                                                .padding(.horizontal, 14)
                                                .padding(.vertical, 8)
                                            Spacer()
                                        }
                                    }
                                },
                                alignment: .topLeading
                            )
                    }
                    
                    // Input status and actions
                    HStack {
                        // API key warning with more compact styling
                        if !settingsManager.isConfigured {
                            HStack(spacing: 6) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(themeManager.currentTheme.colors.warning)
                                
                                Text("API key required")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(themeManager.currentTheme.colors.warning)
                                
                                Button("Configure") {
                                    // Will open settings via app state
                                }
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(themeManager.currentTheme.colors.accent)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(themeManager.currentTheme.colors.warning.opacity(0.1))
                            .cornerRadius(themeManager.currentTheme.cornerRadius.sm)
                        }
                        
                        Spacer()
                        
                        // Character count with more compact styling
                        if !inputText.isEmpty {
                            Text("\(inputText.count)")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(themeManager.currentTheme.colors.tertiaryText)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(themeManager.currentTheme.colors.tertiaryBackground.opacity(0.5))
                                .cornerRadius(themeManager.currentTheme.cornerRadius.sm)
                        }
                    }
                    .padding(.horizontal, 2)
                }
                
                // Send button with more compact styling
                Button(action: sendMessage) {
                    ZStack {
                        Circle()
                            .fill(
                                canSend ? 
                                themeManager.currentTheme.colors.accent : 
                                themeManager.currentTheme.colors.tertiaryBackground
                            )
                            .frame(width: 30, height: 30)
                        
                        Image(systemName: chatManager.isLoading ? "stop.fill" : "arrow.up")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(canSend ? .white : themeManager.currentTheme.colors.tertiaryText)
                    }
                }
                .buttonStyle(.plain)
                .disabled(!canSend && !chatManager.isLoading)
                .help(chatManager.isLoading ? "Stop generation" : "Send message")
                .scaleEffect(canSend ? 1.0 : 0.9)
                .animation(.easeInOut(duration: 0.2), value: canSend)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .themedBackground(.primary)
        .onDrop(of: [.fileURL, .image], isTargeted: $isDragOver) { providers in
            handleDroppedFiles(providers)
            return true
        }
        .fileImporter(
            isPresented: $isFilePickerPresented,
            allowedContentTypes: [.image, .text, .sourceCode, .data],
            allowsMultipleSelection: true
        ) { result in
            handleFileSelection(result)
        }
        .onSubmit {
            if !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                sendMessage()
            }
        }
        .keyboardShortcut(.return, modifiers: .command)
    }
    
    private var canSend: Bool {
        settingsManager.isConfigured &&
        (!inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !selectedFiles.isEmpty) &&
        !chatManager.isLoading
    }
    
    private func sendMessage() {
        if chatManager.isLoading {
            chatManager.stopGenerating()
        } else if canSend {
            let message = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
            chatManager.sendMessage(message, files: selectedFiles)
            
            // Clear input
            inputText = ""
            selectedFiles = []
        }
    }
    
    private func handleDroppedFiles(_ providers: [NSItemProvider]) {
        var newFiles: [UploadedFile] = []
        let group = DispatchGroup()
        
        for provider in providers {
            group.enter()
            
            if provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
                provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { (item, error) in
                    defer { group.leave() }
                    
                    guard let url = item as? URL else { return }
                    
                    do {
                        let data = try Data(contentsOf: url)
                        let file = createUploadedFile(from: url, data: data)
                        newFiles.append(file)
                    } catch {
                        print("Error reading file: \(error)")
                    }
                }
            }
        }
        
        group.notify(queue: .main) {
            selectedFiles.append(contentsOf: newFiles)
        }
    }
    
    private func handleFileSelection(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            for url in urls {
                if url.startAccessingSecurityScopedResource() {
                    defer { url.stopAccessingSecurityScopedResource() }
                    
                    do {
                        let data = try Data(contentsOf: url)
                        let file = createUploadedFile(from: url, data: data)
                        selectedFiles.append(file)
                    } catch {
                        print("Error reading file: \(error)")
                    }
                }
            }
        case .failure(let error):
            print("File selection error: \(error)")
        }
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
}

struct FileAttachmentsView: View {
    @Binding var files: [UploadedFile]
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "paperclip")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(themeManager.currentTheme.colors.accent)
                    
                    Text("Attached files (\(files.count))")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(themeManager.currentTheme.colors.primaryText)
                }
                
                Spacer()
                
                Button("Clear all") {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        files.removeAll()
                    }
                }
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(themeManager.currentTheme.colors.error)
                .modernButton(style: .ghost, size: .small)
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(files) { file in
                        FileAttachmentCard(file: file) {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                files.removeAll { $0.id == file.id }
                            }
                        }
                    }
                }
                .padding(.horizontal, 2)
                .padding(.vertical, 2)
            }
        }
        .padding(12)
        .background(themeManager.currentTheme.colors.surfaceBackground)
        .cornerRadius(themeManager.currentTheme.cornerRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: themeManager.currentTheme.cornerRadius.md)
                .stroke(themeManager.currentTheme.colors.primaryBorder.opacity(0.5), lineWidth: 1)
        )
    }
}

struct FileAttachmentCard: View {
    let file: UploadedFile
    let onRemove: () -> Void
    
    @EnvironmentObject var themeManager: ThemeManager
    @State private var isHovering = false
    
    var body: some View {
        VStack(spacing: 6) {
            ZStack(alignment: .topTrailing) {
                // File preview with more compact styling
                RoundedRectangle(cornerRadius: themeManager.currentTheme.cornerRadius.sm)
                    .fill(themeManager.currentTheme.colors.tertiaryBackground)
                    .frame(width: 52, height: 52)
                    .overlay(
                        Image(systemName: file.type.icon)
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(colorForFileType(file.type))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: themeManager.currentTheme.cornerRadius.sm)
                            .stroke(themeManager.currentTheme.colors.primaryBorder.opacity(0.3), lineWidth: 1)
                    )
                
                // Remove button with more compact styling
                Button(action: onRemove) {
                    ZStack {
                        Circle()
                            .fill(themeManager.currentTheme.colors.error)
                            .frame(width: 16, height: 16)
                        
                        Image(systemName: "xmark")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                .buttonStyle(.plain)
                .offset(x: 6, y: -6)
                .opacity(isHovering ? 1.0 : 0.7)
                .scaleEffect(isHovering ? 1.1 : 1.0)
                .animation(.easeInOut(duration: 0.2), value: isHovering)
            }
            
            // File name with more compact typography
            VStack(spacing: 2) {
                Text(file.name)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(themeManager.currentTheme.colors.primaryText)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .frame(width: 64)
                
                Text(formatFileSize(file.size))
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(themeManager.currentTheme.colors.tertiaryText)
            }
        }
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovering = hovering
            }
        }
    }
    
    private func colorForFileType(_ type: UploadedFile.FileType) -> Color {
        switch type {
        case .image:
            return .green
        case .code:
            return .blue
        case .text:
            return .orange
        case .other:
            return themeManager.currentTheme.colors.secondaryText
        }
    }
    
    private func formatFileSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}

#Preview {
    ChatInputView()
        .environmentObject(ChatManager())
        .environmentObject(SettingsManager())
        .frame(width: 600, height: 200)
} 