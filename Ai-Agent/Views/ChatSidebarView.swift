//
//  ChatSidebarView.swift
//  Ai-Agent
//
//  Created by Chris Lane on 6/18/25.
//

import SwiftUI

struct ChatSidebarView: View {
    @EnvironmentObject var chatManager: ChatManager
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var themeManager: ThemeManager
    @Binding var showSidebar: Bool
    @State private var searchText = ""
    @State private var isSearchFocused = false
    
    var filteredSessions: [ChatSession] {
        if searchText.isEmpty {
            return chatManager.sessions
        } else {
            return chatManager.sessions.filter { session in
                session.title.localizedCaseInsensitiveContains(searchText) ||
                session.messages.contains { message in
                    message.content.localizedCaseInsensitiveContains(searchText)
                }
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("AI Agent")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(themeManager.currentTheme.colors.primaryText)
                        
                        Text("Intelligent Conversations")
                            .font(.caption)
                            .foregroundColor(themeManager.currentTheme.colors.secondaryText)
                    }
                    
                    Spacer()
                    
                    Button(action: chatManager.startNewChat) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(themeManager.currentTheme.colors.accent)
                    }
                    .buttonStyle(.plain)
                    .keyboardShortcut("n", modifiers: .command)
                    .help("New Conversation")
                }
                
                // Modern Search Bar with subtle border
                HStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(isSearchFocused ? 
                                       themeManager.currentTheme.colors.accent : 
                                       themeManager.currentTheme.colors.secondaryText)
                    
                    TextField("Search conversations...", text: $searchText)
                        .textFieldStyle(.plain)
                        .font(.system(size: 14))
                        .onSubmit {
                            // Handle search
                        }
                    
                    if !searchText.isEmpty {
                        Button(action: { searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 14))
                                .foregroundColor(themeManager.currentTheme.colors.tertiaryText)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(themeManager.currentTheme.colors.surfaceBackground)
                .cornerRadius(themeManager.currentTheme.cornerRadius.lg)
                .overlay(
                    RoundedRectangle(cornerRadius: themeManager.currentTheme.cornerRadius.lg)
                        .stroke(isSearchFocused ? 
                               themeManager.currentTheme.colors.focusBorder : 
                               themeManager.currentTheme.colors.primaryBorder, 
                               lineWidth: isSearchFocused ? 2 : 1)
                )
                .animation(.easeInOut(duration: 0.2), value: isSearchFocused)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 16)
            .themedBackground(.primary)
            
            // Divider with subtle styling
            Rectangle()
                .fill(themeManager.currentTheme.colors.primaryBorder.opacity(0.3))
                .frame(height: 1)
            
            // Chat list
            ScrollView {
                LazyVStack(spacing: 8) {
                    if filteredSessions.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: searchText.isEmpty ? "message" : "magnifyingglass")
                                .font(.system(size: 32))
                                .foregroundColor(themeManager.currentTheme.colors.tertiaryText)
                            
                            Text(searchText.isEmpty ? "No conversations yet" : "No matching conversations")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(themeManager.currentTheme.colors.secondaryText)
                            
                            if searchText.isEmpty {
                                Text("Start a new conversation to get going")
                                    .font(.system(size: 14))
                                    .foregroundColor(themeManager.currentTheme.colors.tertiaryText)
                                    .multilineTextAlignment(.center)
                            }
                        }
                        .padding(.top, 60)
                    } else {
                        ForEach(filteredSessions) { session in
                            ChatSessionRow(
                                session: session,
                                isSelected: session.id == chatManager.currentSession.id,
                                onSelect: { chatManager.loadSession(session) },
                                onDelete: { chatManager.deleteSession(session) }
                            )
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 16)
            }
            .themedBackground(.primary)
            
            // Footer with subtle top border
            VStack(spacing: 16) {
                Rectangle()
                    .fill(themeManager.currentTheme.colors.primaryBorder.opacity(0.3))
                    .frame(height: 1)
                
                HStack(spacing: 16) {
                    Button(action: { appState.showSettings = true }) {
                        HStack(spacing: 8) {
                            Image(systemName: "gearshape.fill")
                                .font(.system(size: 16))
                            Text("Settings")
                                .font(.system(size: 14, weight: .medium))
                        }
                        .foregroundColor(themeManager.currentTheme.colors.primaryText)
                    }
                    .buttonStyle(.plain)
                    .keyboardShortcut(",", modifiers: .command)
                    
                    Spacer()
                    
                    HStack(spacing: 12) {
                        Button(action: chatManager.importChat) {
                            Image(systemName: "square.and.arrow.down")
                                .font(.system(size: 16))
                                .foregroundColor(themeManager.currentTheme.colors.accent)
                        }
                        .buttonStyle(.plain)
                        .help("Import Chat")
                        
                        Button(action: chatManager.exportCurrentChat) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 16))
                                .foregroundColor(themeManager.currentTheme.colors.accent)
                        }
                        .buttonStyle(.plain)
                        .help("Export Chat")
                        .disabled(chatManager.currentSession.messages.isEmpty)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .themedBackground(.primary)
        }
        .themedBackground(.primary)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct ChatSessionRow: View {
    let session: ChatSession
    let isSelected: Bool
    let onSelect: () -> Void
    let onDelete: () -> Void
    
    @EnvironmentObject var themeManager: ThemeManager
    @State private var isHovering = false
    
    var body: some View {
        HStack(spacing: 16) {
            // Session icon
            Circle()
                .fill(
                    isSelected ? 
                    themeManager.currentTheme.colors.accent : 
                    themeManager.currentTheme.colors.tertiaryBackground
                )
                .frame(width: 36, height: 36)
                .overlay(
                    Image(systemName: isSelected ? "message.fill" : "message")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(
                            isSelected ? 
                            .white : 
                            themeManager.currentTheme.colors.secondaryText
                        )
                )
            
            VStack(alignment: .leading, spacing: 6) {
                Text(session.title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(
                        isSelected ? 
                        themeManager.currentTheme.colors.accent : 
                        themeManager.currentTheme.colors.primaryText
                    )
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                HStack(spacing: 8) {
                    if let lastMessage = session.lastMessage {
                        Text(formatTimestamp(lastMessage.timestamp))
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(themeManager.currentTheme.colors.secondaryText)
                    }
                    
                    Text("•")
                        .font(.system(size: 10))
                        .foregroundColor(themeManager.currentTheme.colors.tertiaryText)
                    
                    Text("\(session.messageCount)")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(themeManager.currentTheme.colors.secondaryText)
                }
            }
            
            Spacer()
            
            // Action buttons
            HStack(spacing: 8) {
                if isHovering || isSelected {
                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .font(.system(size: 14))
                            .foregroundColor(themeManager.currentTheme.colors.error)
                    }
                    .buttonStyle(.plain)
                    .help("Delete Conversation")
                    .opacity(isHovering || isSelected ? 1.0 : 0.0)
                    .animation(.easeInOut(duration: 0.2), value: isHovering || isSelected)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: themeManager.currentTheme.cornerRadius.lg)
                .fill(
                    isSelected ? 
                    themeManager.currentTheme.colors.accent.opacity(0.1) : 
                    isHovering ? 
                    themeManager.currentTheme.colors.surfaceBackground : 
                    Color.clear
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: themeManager.currentTheme.cornerRadius.lg)
                .stroke(
                    isSelected ? 
                    themeManager.currentTheme.colors.accent.opacity(0.3) : 
                    Color.clear,
                    lineWidth: 2
                )
        )
        .contentShape(Rectangle())
        .onTapGesture(perform: onSelect)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovering = hovering
            }
        }
        .scaleEffect(isHovering ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isHovering)
    }
    
    private func formatTimestamp(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

#Preview {
    ChatSidebarView(showSidebar: .constant(true))
        .environmentObject(ChatManager())
        .environmentObject(AppState())
        .frame(width: 280, height: 600)
} 