//
//  ThemeManager.swift
//  InterPrep
//
//  Theme management system
//

import SwiftUI

public enum ThemeMode: String, CaseIterable, Identifiable {
    case light = "Светлая"
    case dark = "Темная"
    case system = "Системная"
    
    public var id: String { rawValue }
    
    var colorScheme: ColorScheme? {
        switch self {
        case .light: return .light
        case .dark: return .dark
        case .system: return nil
        }
    }
}

@MainActor
public class ThemeManager: ObservableObject {
    @Published public private(set) var currentMode: ThemeMode
    
    private let userDefaultsKey = "app_theme_mode"
    
    public static let shared = ThemeManager()
    
    private init() {
        if let savedMode = UserDefaults.standard.string(forKey: userDefaultsKey),
           let mode = ThemeMode(rawValue: savedMode) {
            self.currentMode = mode
        } else {
            self.currentMode = .system
        }
    }
    
    public func setTheme(_ mode: ThemeMode) {
        currentMode = mode
        UserDefaults.standard.set(mode.rawValue, forKey: userDefaultsKey)
    }
    
    public var colorScheme: ColorScheme? {
        currentMode.colorScheme
    }
}

public extension View {
    func applyTheme() -> some View {
        self.modifier(ThemeModifier())
    }
}

private struct ThemeModifier: ViewModifier {
    @StateObject private var themeManager = ThemeManager.shared
    
    func body(content: Content) -> some View {
        content
            .preferredColorScheme(themeManager.colorScheme)
    }
}
