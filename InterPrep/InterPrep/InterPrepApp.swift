//
//  InterPrepApp.swift
//  InterPrep
//
//  Created by Наталья Захарова on 21.01.2026.
//

import SwiftUI
import DesignSystem

@main
struct InterPrepApp: App {
    @StateObject private var appCoordinator = AppCoordinator()
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some Scene {
        WindowGroup {
            appCoordinator.rootView
                .preferredColorScheme(themeManager.colorScheme)
        }
    }
}

// MARK: - App Coordinator

@MainActor
final class AppCoordinator: ObservableObject {
    @Published var appState: AppState
    
    private let appGraph = AppGraph()
    
    enum AppState {
        case onboarding
        case auth
        case main
    }
    
    init() {
        // Определяем начальное состояние
        if appGraph.shouldShowOnboarding() {
            self.appState = .onboarding
        } else {
            // TODO: Проверить авторизацию
            // Пока всегда показываем Auth после онбординга
            self.appState = .auth
        }
    }
    
    @ViewBuilder
    var rootView: some View {
        Group {
            switch appState {
            case .onboarding:
                appGraph.makeOnboardingContainer {
                    withAnimation(.easeInOut(duration: 0.4)) {
                        self.appState = .auth
                    }
                }
                
            case .auth:
                appGraph.makeAuthContainer {
                    withAnimation(.easeInOut(duration: 0.4)) {
                        self.appState = .main
                    }
                }
                
            case .main:
                appGraph.makeMainContainer()
            }
        }
        .transition(.opacity)
        .animation(.easeInOut(duration: 0.4), value: appState)
    }
}
