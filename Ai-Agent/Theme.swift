//
//  Theme.swift
//  Ai-Agent
//
//  Created by Chris Lane on 6/18/25.
//

import SwiftUI
import AppKit
import Combine

// MARK: - Theme Manager
class ThemeManager: ObservableObject {
    static let shared = ThemeManager()
    
    @Published private(set) var currentTheme: Theme = .system
    
    private init() {
        updateTheme()
        
        // Listen for system appearance changes
        NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { _ in
            self.updateTheme()
        }
    }
    
    func setTheme(_ theme: Theme) {
        currentTheme = theme
        updateTheme()
    }
    
    private func updateTheme() {
        DispatchQueue.main.async {
            self.objectWillChange.send()
        }
    }
}

// MARK: - Theme Definition
struct Theme {
    let colors: ColorScheme
    let typography: Typography
    let spacing: Spacing
    let cornerRadius: CornerRadius
    let shadows: Shadows
    
    static let system = Theme(
        colors: .system,
        typography: .system,
        spacing: .system,
        cornerRadius: .system,
        shadows: .system
    )
}

// MARK: - Color Scheme
struct ColorScheme {
    // Background colors
    let primaryBackground: Color
    let secondaryBackground: Color
    let tertiaryBackground: Color
    let surfaceBackground: Color
    
    // Content colors
    let primaryText: Color
    let secondaryText: Color
    let tertiaryText: Color
    let placeholderText: Color
    
    // Interactive colors
    let accent: Color
    let accentHover: Color
    let accentPressed: Color
    
    // System colors
    let success: Color
    let warning: Color
    let error: Color
    let info: Color
    
    // Border colors
    let primaryBorder: Color
    let secondaryBorder: Color
    let focusBorder: Color
    
    static let system = ColorScheme(
        // Backgrounds - Modern glass morphism inspired
        primaryBackground: Color(NSColor.windowBackgroundColor),
        secondaryBackground: Color(NSColor.underPageBackgroundColor),
        tertiaryBackground: Color(NSColor.controlBackgroundColor),
        surfaceBackground: Color(NSColor.textBackgroundColor),
        
        // Content
        primaryText: Color(NSColor.labelColor),
        secondaryText: Color(NSColor.secondaryLabelColor),
        tertiaryText: Color(NSColor.tertiaryLabelColor),
        placeholderText: Color(NSColor.placeholderTextColor),
        
        // Interactive
        accent: Color(NSColor.controlAccentColor),
        accentHover: Color(NSColor.controlAccentColor).opacity(0.8),
        accentPressed: Color(NSColor.controlAccentColor).opacity(0.6),
        
        // System
        success: Color(.systemGreen),
        warning: Color(.systemOrange),
        error: Color(.systemRed),
        info: Color(.systemBlue),
        
        // Borders
        primaryBorder: Color(NSColor.separatorColor),
        secondaryBorder: Color(NSColor.separatorColor).opacity(0.5),
        focusBorder: Color(NSColor.controlAccentColor)
    )
}

// MARK: - Typography
struct Typography {
    let largeTitle: Font
    let title: Font
    let title2: Font
    let title3: Font
    let headline: Font
    let body: Font
    let callout: Font
    let subheadline: Font
    let footnote: Font
    let caption: Font
    let caption2: Font
    
    static let system = Typography(
        largeTitle: .largeTitle,
        title: .title,
        title2: .title2,
        title3: .title3,
        headline: .headline,
        body: .body,
        callout: .callout,
        subheadline: .subheadline,
        footnote: .footnote,
        caption: .caption,
        caption2: .caption2
    )
}

// MARK: - Spacing
struct Spacing {
    let xs: CGFloat = 4
    let sm: CGFloat = 8
    let md: CGFloat = 12
    let lg: CGFloat = 16
    let xl: CGFloat = 20
    let xxl: CGFloat = 24
    let xxxl: CGFloat = 32
    
    static let system = Spacing()
}

// MARK: - Corner Radius
struct CornerRadius {
    let xs: CGFloat = 4
    let sm: CGFloat = 6
    let md: CGFloat = 8
    let lg: CGFloat = 12
    let xl: CGFloat = 16
    let xxl: CGFloat = 20
    
    static let system = CornerRadius()
}

// MARK: - Shadows
struct Shadows {
    let small: (color: Color, radius: CGFloat, x: CGFloat, y: CGFloat)
    let medium: (color: Color, radius: CGFloat, x: CGFloat, y: CGFloat)
    let large: (color: Color, radius: CGFloat, x: CGFloat, y: CGFloat)
    
    static let system = Shadows(
        small: (Color.black.opacity(0.1), 2, 0, 1),
        medium: (Color.black.opacity(0.15), 4, 0, 2),
        large: (Color.black.opacity(0.2), 8, 0, 4)
    )
}

// MARK: - View Extensions
extension View {
    func themedBackground(_ level: BackgroundLevel = .primary) -> some View {
        let theme = ThemeManager.shared.currentTheme
        let color: Color
        
        switch level {
        case .primary:
            color = theme.colors.primaryBackground
        case .secondary:
            color = theme.colors.secondaryBackground
        case .tertiary:
            color = theme.colors.tertiaryBackground
        case .surface:
            color = theme.colors.surfaceBackground
        }
        
        return self.background(color)
    }
    
    func themedShadow(_ level: ShadowLevel = .medium) -> some View {
        let theme = ThemeManager.shared.currentTheme
        let shadow: (color: Color, radius: CGFloat, x: CGFloat, y: CGFloat)
        
        switch level {
        case .small:
            shadow = theme.shadows.small
        case .medium:
            shadow = theme.shadows.medium
        case .large:
            shadow = theme.shadows.large
        }
        
        return self.shadow(
            color: shadow.color,
            radius: shadow.radius,
            x: shadow.x,
            y: shadow.y
        )
    }
    
    func modernCard(padding: CGFloat = 16) -> some View {
        let theme = ThemeManager.shared.currentTheme
        
        return self
            .padding(padding)
            .background(theme.colors.surfaceBackground)
            .cornerRadius(theme.cornerRadius.lg)
            .themedShadow(.small)
            .overlay(
                RoundedRectangle(cornerRadius: theme.cornerRadius.lg)
                    .stroke(theme.colors.primaryBorder, lineWidth: 0.5)
            )
    }
    
    func modernButton(style: ButtonStyle = .primary, size: ButtonSize = .medium) -> some View {
        ModernButton(style: style, size: size) {
            self
        }
    }
}

enum BackgroundLevel {
    case primary, secondary, tertiary, surface
}

enum ShadowLevel {
    case small, medium, large
}

// MARK: - Modern Button Styles
enum ButtonStyle {
    case primary, secondary, tertiary, ghost
}

enum ButtonSize {
    case small, medium, large
}

struct ModernButton<Content: View>: View {
    let style: ButtonStyle
    let size: ButtonSize
    let content: Content
    
    @State private var isHovered = false
    @State private var isPressed = false
    
    init(style: ButtonStyle, size: ButtonSize, @ViewBuilder content: () -> Content) {
        self.style = style
        self.size = size
        self.content = content()
    }
    
    var body: some View {
        let theme = ThemeManager.shared.currentTheme
        
        content
            .padding(paddingForSize)
            .background(backgroundForStyle(theme))
            .foregroundColor(foregroundForStyle(theme))
            .cornerRadius(theme.cornerRadius.md)
            .overlay(
                RoundedRectangle(cornerRadius: theme.cornerRadius.md)
                    .stroke(borderForStyle(theme), lineWidth: 1)
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: isPressed)
            .animation(.easeInOut(duration: 0.2), value: isHovered)
            .onHover { isHovered = $0 }
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.1)) {
                    isPressed = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.easeInOut(duration: 0.1)) {
                        isPressed = false
                    }
                }
            }
    }
    
    private var paddingForSize: EdgeInsets {
        switch size {
        case .small:
            return EdgeInsets(top: 6, leading: 12, bottom: 6, trailing: 12)
        case .medium:
            return EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16)
        case .large:
            return EdgeInsets(top: 12, leading: 20, bottom: 12, trailing: 20)
        }
    }
    
    private func backgroundForStyle(_ theme: Theme) -> Color {
        switch style {
        case .primary:
            return isPressed ? theme.colors.accentPressed : 
                   isHovered ? theme.colors.accentHover : theme.colors.accent
        case .secondary:
            return isPressed ? theme.colors.tertiaryBackground : 
                   isHovered ? theme.colors.secondaryBackground : theme.colors.tertiaryBackground
        case .tertiary:
            return isPressed ? theme.colors.secondaryBackground.opacity(0.8) : 
                   isHovered ? theme.colors.secondaryBackground.opacity(0.6) : Color.clear
        case .ghost:
            return isPressed ? theme.colors.accent.opacity(0.1) : 
                   isHovered ? theme.colors.accent.opacity(0.05) : Color.clear
        }
    }
    
    private func foregroundForStyle(_ theme: Theme) -> Color {
        switch style {
        case .primary:
            return .white
        case .secondary, .tertiary, .ghost:
            return theme.colors.primaryText
        }
    }
    
    private func borderForStyle(_ theme: Theme) -> Color {
        switch style {
        case .primary:
            return Color.clear
        case .secondary:
            return theme.colors.primaryBorder
        case .tertiary, .ghost:
            return isHovered ? theme.colors.primaryBorder : Color.clear
        }
    }
}