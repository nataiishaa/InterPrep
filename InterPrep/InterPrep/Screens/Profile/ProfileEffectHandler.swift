//
//  ProfileEffectHandler.swift
//  InterPrep
//
//  Profile effect handler
//

import Foundation
import SwiftUI
import ArchitectureCore
import DesignSystem

public actor ProfileEffectHandler: EffectHandler {
    public typealias S = ProfileState
    
    private let userDefaults = UserDefaults.standard
    private let userKey = "user_profile"
    private let settingsKey = "app_settings"
    private let statisticsKey = "user_statistics"
    
    public init() {}
    
    public func handle(effect: ProfileState.Effect) async -> ProfileState.Feedback? {
        switch effect {
        case .loadUser:
            return await loadUser()
            
        case .loadStatistics:
            return await loadStatistics()
            
        case let .updateProfile(user):
            return await updateProfile(user)
            
        case let .saveSettings(settings):
            return await saveSettings(settings)
            
        case .navigateToResumeUpload:
            // Navigation handled by coordinator
            return nil
            
        case .performLogout:
            return await performLogout()
            
        case .performDeleteAccount:
            return await performDeleteAccount()
        }
    }
    
    // MARK: - Private Methods
    
    private func loadUser() async -> ProfileState.Feedback {
        // Load and apply saved theme
        await loadAndApplyTheme()
        
        do {
            if let data = userDefaults.data(forKey: userKey) {
                let user = try JSONDecoder().decode(ProfileState.User.self, from: data)
                return .userLoaded(user)
            } else {
                // Create default user
                let defaultUser = ProfileState.User(
                    id: UUID().uuidString,
                    firstName: "Пользователь",
                    lastName: "",
                    email: "user@example.com",
                    phone: nil,
                    avatarURL: nil,
                    position: nil,
                    experience: nil,
                    registeredDate: Date()
                )
                
                let data = try JSONEncoder().encode(defaultUser)
                userDefaults.set(data, forKey: userKey)
                
                return .userLoaded(defaultUser)
            }
        } catch {
            return .loadingFailed("Не удалось загрузить профиль")
        }
    }
    
    private func loadAndApplyTheme() async {
        if let data = userDefaults.data(forKey: settingsKey),
           let settings = try? JSONDecoder().decode(ProfileState.AppSettings.self, from: data) {
            await applyTheme(settings.theme)
        }
    }
    
    private func loadStatistics() async -> ProfileState.Feedback {
        do {
            if let data = userDefaults.data(forKey: statisticsKey) {
                let statistics = try JSONDecoder().decode(ProfileState.Statistics.self, from: data)
                return .statisticsLoaded(statistics)
            } else {
                // Return default statistics
                return .statisticsLoaded(ProfileState.Statistics())
            }
        } catch {
            return .statisticsLoaded(ProfileState.Statistics())
        }
    }
    
    private func updateProfile(_ user: ProfileState.User) async -> ProfileState.Feedback {
        do {
            let data = try JSONEncoder().encode(user)
            userDefaults.set(data, forKey: userKey)
            return .profileUpdated(user)
        } catch {
            return .loadingFailed("Не удалось сохранить профиль")
        }
    }
    
    private func saveSettings(_ settings: ProfileState.AppSettings) async -> ProfileState.Feedback {
        do {
            let data = try JSONEncoder().encode(settings)
            userDefaults.set(data, forKey: settingsKey)
            
            // Apply theme change
            await applyTheme(settings.theme)
            
            return .settingsSaved
        } catch {
            return .loadingFailed("Не удалось сохранить настройки")
        }
    }
    
    @MainActor
    private func applyTheme(_ theme: ProfileState.AppSettings.Theme) {
        let themeMode: ThemeMode
        switch theme {
        case .light:
            themeMode = .light
        case .dark:
            themeMode = .dark
        case .system:
            themeMode = .system
        }
        ThemeManager.shared.setTheme(themeMode)
    }
    
    private func performLogout() async -> ProfileState.Feedback {
        // Clear user data
        userDefaults.removeObject(forKey: userKey)
        userDefaults.removeObject(forKey: statisticsKey)
        userDefaults.set(false, forKey: "isOnboardingCompleted")
        
        // Note: App restart/navigation should be handled by the app coordinator
        // The effect handler should only handle data operations
        return .logoutCompleted
    }
    
    private func performDeleteAccount() async -> ProfileState.Feedback {
        // Clear all user data
        userDefaults.removeObject(forKey: userKey)
        userDefaults.removeObject(forKey: statisticsKey)
        userDefaults.removeObject(forKey: settingsKey)
        userDefaults.removeObject(forKey: "calendar_events")
        userDefaults.removeObject(forKey: "caldav_settings")
        userDefaults.set(false, forKey: "isOnboardingCompleted")
        
        // Note: App restart/navigation should be handled by the app coordinator
        // The effect handler should only handle data operations
        return .accountDeleted
    }
    
}
