//
//  ChatInterfaceView.swift
//  Ai-Agent
//
//  Created by Chris Lane on 6/18/25.
//

import SwiftUI
import Combine

struct ChatInterfaceView: View {
    @EnvironmentObject var chatManager: ChatManager
    @EnvironmentObject var settingsManager: SettingsManager
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(spacing: 0) {
            // Messages area with modern glass effect
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 20) {
                        if chatManager.currentSession.messages.isEmpty {
                            WelcomeView()
                                .padding(.top, 80)
                        } else {
                            ForEach(chatManager.currentSession.messages) { message in
                                ChatMessageView(
                                    message: message,
                                    isStreaming: message.id == chatManager.streamingMessageId
                                )
                                .id(message.id)
                            }
                        }
                    }
                    .padding(.horizontal, 32)
                    .padding(.vertical, 24)
                }
                .themedBackground(.primary)
                .onChange(of: chatManager.currentSession.messages.count) {
                    withAnimation(.easeOut(duration: 0.4)) {
                        if let lastMessage = chatManager.currentSession.messages.last {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
            }
            
            // Input area with subtle border separation
            ChatInputView()
        }
        .themedBackground(.primary)
    }
}

struct WelcomeView: View {
    @EnvironmentObject var settingsManager: SettingsManager
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        VStack(spacing: 32) {
            // Hero section with animated gradient
            VStack(spacing: 20) {
                // AI brain icon with glow effect
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    themeManager.currentTheme.colors.accent.opacity(0.3),
                                    themeManager.currentTheme.colors.accent.opacity(0.1),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 20,
                                endRadius: 60
                            )
                        )
                        .frame(width: 120, height: 120)
                    
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 56, weight: .medium))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    themeManager.currentTheme.colors.accent,
                                    themeManager.currentTheme.colors.accent.opacity(0.8)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                
                VStack(spacing: 12) {
                    Text("Welcome to AI Agent")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(themeManager.currentTheme.colors.primaryText)
                    
                    Text("Your intelligent assistant for conversations, code analysis, and creative tasks")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(themeManager.currentTheme.colors.secondaryText)
                        .multilineTextAlignment(.center)
                        .lineLimit(3)
                }
            }
            
            // Feature cards
            VStack(spacing: 20) {
                Text("What would you like to do?")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(themeManager.currentTheme.colors.primaryText)
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 2), spacing: 16) {
                    WelcomeFeatureCard(
                        icon: "message.badge.circle",
                        title: "Start Chatting",
                        description: "Ask questions, get help, or have a conversation",
                        color: .blue
                    ) {
                        // Focus on input
                    }
                    
                    WelcomeFeatureCard(
                        icon: "doc.text.magnifyingglass",
                        title: "Analyze Files",
                        description: "Upload documents, images, or code for analysis",
                        color: .green
                    ) {
                        // Show file picker
                    }
                    
                    WelcomeFeatureCard(
                        icon: "brain",
                        title: "Code Review",
                        description: "Get help with programming and code analysis",
                        color: .purple
                    ) {
                        // Template for code
                    }
                    
                    WelcomeFeatureCard(
                        icon: "lightbulb",
                        title: "Creative Writing",
                        description: "Brainstorm ideas and creative content",
                        color: .orange
                    ) {
                        // Template for creative tasks
                    }
                }
                .frame(maxWidth: 520)
                
                // Configuration warning if needed
                if !settingsManager.isConfigured {
                    HStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(themeManager.currentTheme.colors.warning)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("API Key Required")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(themeManager.currentTheme.colors.primaryText)
                            
                            Text("Configure your OpenAI API key to start using AI Agent")
                                .font(.system(size: 12))
                                .foregroundColor(themeManager.currentTheme.colors.secondaryText)
                        }
                        
                        Spacer()
                        
                        Button("Configure") {
                            appState.showSettings = true
                        }
                        .modernButton(style: .primary, size: .small)
                    }
                    .padding(16)
                    .background(themeManager.currentTheme.colors.warning.opacity(0.1))
                    .cornerRadius(themeManager.currentTheme.cornerRadius.lg)
                    .overlay(
                        RoundedRectangle(cornerRadius: themeManager.currentTheme.cornerRadius.lg)
                            .stroke(themeManager.currentTheme.colors.warning.opacity(0.3), lineWidth: 1)
                    )
                }
            }
        }
        .padding(.horizontal, 40)
        .frame(maxWidth: 600)
    }
}

struct WelcomeFeatureCard: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    let action: () -> Void
    
    @EnvironmentObject var themeManager: ThemeManager
    @State private var isHovering = false
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 16) {
                // Icon with colored background
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: icon)
                        .font(.system(size: 22, weight: .medium))
                        .foregroundColor(color)
                }
                
                VStack(spacing: 6) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(themeManager.currentTheme.colors.primaryText)
                        .multilineTextAlignment(.center)
                    
                    Text(description)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(themeManager.currentTheme.colors.secondaryText)
                        .multilineTextAlignment(.center)
                        .lineLimit(3)
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity, minHeight: 140)
            .background(
                RoundedRectangle(cornerRadius: themeManager.currentTheme.cornerRadius.xl)
                    .fill(
                        isHovering ? 
                        themeManager.currentTheme.colors.surfaceBackground : 
                        themeManager.currentTheme.colors.tertiaryBackground
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: themeManager.currentTheme.cornerRadius.xl)
                    .stroke(
                        isHovering ? 
                        color.opacity(0.3) : 
                        themeManager.currentTheme.colors.primaryBorder,
                        lineWidth: isHovering ? 2 : 1
                    )
            )
            .scaleEffect(isHovering ? 1.05 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isHovering)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovering = hovering
            }
        }
    }
}

#Preview {
    ChatInterfaceView()
        .environmentObject(ChatManager())
        .environmentObject(SettingsManager())
        .frame(width: 800, height: 600)
} 