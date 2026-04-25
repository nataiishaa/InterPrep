//
//  InterPrepApp.swift
//  InterPrep
//
//  Created by Наталья Захарова on 21.01.2026.
//

import DesignSystem
import NetworkService
import SwiftUI

@main
struct InterPrepApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var appCoordinator = AppCoordinator()
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some Scene {
        WindowGroup {
            appCoordinator.rootView
                .preferredColorScheme(themeManager.colorScheme)
        }
    }
}

@MainActor
final class AppCoordinator: ObservableObject {
    @Published var appState: AppState
    
    private let appGraph = AppGraph()
    
    enum AppState {
        case onboarding
        case auth
        case main
    }
    
    private static let accessTokenKey = "com.interprep.access_token"
    private static let refreshTokenKey = "com.interprep.refresh_token"
    
    init() {
        if appGraph.shouldShowOnboarding() {
            self.appState = .onboarding
        } else if Self.hasStoredSession() {
            self.appState = .main
        } else {
            self.appState = .auth
        }
        
        Task {
            await NetworkServiceV2.shared.setSessionDelegate(self)
        }
    }
    
    private static func hasStoredSession() -> Bool {
        if TokenStorage.hasStoredTokensInKeychain() { return true }
        // Pre-migration fallback: tokens may still be in UserDefaults before TokenStorage.init() runs
        let ud = UserDefaults.standard
        return ud.string(forKey: accessTokenKey) != nil && ud.string(forKey: refreshTokenKey) != nil
    }
    
    private func handleSessionInvalidation() {
        Task {
            await NetworkServiceV2.shared.clearTokens()
            
            withAnimation(.easeInOut(duration: 0.4)) {
                self.appState = .auth
            }
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
                appGraph.makeMainContainer(onLogout: {
                    withAnimation(.easeInOut(duration: 0.4)) {
                        self.appState = .auth
                    }
                })
            }
        }
        .transition(.opacity)
        .animation(.easeInOut(duration: 0.4), value: appState)
    }
}

extension AppCoordinator: @unchecked Sendable {}

extension AppCoordinator: SessionInvalidationDelegate {
    nonisolated func sessionDidInvalidate() {
        Task { @MainActor in
            handleSessionInvalidation()
        }
    }
}
