//
//  Colors.swift
//  InterPrep
//
//  Design system colors with dark mode support
//

import SwiftUI

public extension Color {
    // MARK: - Brand Colors
    
    static var brandPrimary: Color {
        Color("BrandPrimary", bundle: .main)
            .fallback(
                light: Color(red: 0.35, green: 0.4, blue: 0.35),
                dark: Color(red: 0.5, green: 0.55, blue: 0.5)
            )
    }
    
    static var brandSecondary: Color {
        Color("BrandSecondary", bundle: .main)
            .fallback(
                light: Color(red: 0.45, green: 0.5, blue: 0.45),
                dark: Color(red: 0.4, green: 0.45, blue: 0.4)
            )
    }
    
    // MARK: - Background
    
    static var backgroundPrimary: Color {
        Color("BackgroundPrimary", bundle: .main)
            .fallback(
                light: Color(UIColor.systemBackground),
                dark: Color(UIColor.systemBackground)
            )
    }
    
    static var backgroundSecondary: Color {
        Color("BackgroundSecondary", bundle: .main)
            .fallback(
                light: Color(UIColor.secondarySystemBackground),
                dark: Color(UIColor.secondarySystemBackground)
            )
    }
    
    static var backgroundGradientStart: Color {
        Color("BackgroundGradientStart", bundle: .main)
            .fallback(
                light: Color(red: 0.45, green: 0.5, blue: 0.45),
                dark: Color(red: 0.15, green: 0.18, blue: 0.15)
            )
    }
    
    static var backgroundGradientEnd: Color {
        Color("BackgroundGradientEnd", bundle: .main)
            .fallback(
                light: Color(red: 0.35, green: 0.4, blue: 0.35),
                dark: Color(red: 0.08, green: 0.1, blue: 0.08)
            )
    }
    
    // MARK: - Text
    
    static var textPrimary: Color {
        Color("TextPrimary", bundle: .main)
            .fallback(
                light: .white,
                dark: Color(UIColor.label)
            )
    }
    
    static var textSecondary: Color {
        Color("TextSecondary", bundle: .main)
            .fallback(
                light: .white.opacity(0.9),
                dark: Color(UIColor.secondaryLabel)
            )
    }
    
    static var textTertiary: Color {
        Color("TextTertiary", bundle: .main)
            .fallback(
                light: .white.opacity(0.8),
                dark: Color(UIColor.tertiaryLabel)
            )
    }
    
    static var textOnBackground: Color {
        Color("TextOnBackground", bundle: .main)
            .fallback(
                light: Color(UIColor.label),
                dark: Color(UIColor.label)
            )
    }
    
    // MARK: - UI Elements
    
    static var cardBackground: Color {
        Color("CardBackground", bundle: .main)
            .fallback(
                light: .white,
                dark: Color(red: 0.15, green: 0.15, blue: 0.15)
            )
    }
    
    static var fieldBackground: Color {
        Color("FieldBackground", bundle: .main)
            .fallback(
                light: .white.opacity(0.95),
                dark: Color(UIColor.tertiarySystemBackground)
            )
    }
    
    static var buttonBackground: Color {
        Color("ButtonBackground", bundle: .main)
            .fallback(
                light: .white,
                dark: Color(red: 0.2, green: 0.22, blue: 0.2)
            )
    }
    
    static var buttonText: Color {
        Color("ButtonText", bundle: .main)
            .fallback(
                light: brandPrimary,
                dark: Color(red: 0.6, green: 0.65, blue: 0.6)
            )
    }
    
    static var divider: Color {
        Color("Divider", bundle: .main)
            .fallback(
                light: Color(UIColor.separator),
                dark: Color(UIColor.separator)
            )
    }
    
    // MARK: - Semantic Colors
    
    static var errorText: Color {
        Color("ErrorText", bundle: .main)
            .fallback(
                light: .red,
                dark: Color(red: 1.0, green: 0.3, blue: 0.3)
            )
    }
    
    static var successText: Color {
        Color("SuccessText", bundle: .main)
            .fallback(
                light: .green,
                dark: Color(red: 0.3, green: 0.9, blue: 0.3)
            )
    }
    
    static var iconTint: Color {
        Color("IconTint", bundle: .main)
            .fallback(
                light: brandPrimary.opacity(0.6),
                dark: Color(red: 0.5, green: 0.55, blue: 0.5)
            )
    }
}

// MARK: - Color Fallback Helper

private extension Color {
    func fallback(light: Color, dark: Color) -> Color {
        // SwiftUI автоматически выберет нужный цвет в зависимости от ColorScheme
        return Color(UIColor { traitCollection in
            switch traitCollection.userInterfaceStyle {
            case .dark:
                return UIColor(dark)
            default:
                return UIColor(light)
            }
        })
    }
}

// MARK: - LinearGradient Extensions

public extension LinearGradient {
    static var brandBackground: LinearGradient {
        LinearGradient(
            colors: [
                .backgroundGradientStart,
                .backgroundGradientEnd
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}
