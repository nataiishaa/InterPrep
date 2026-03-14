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

/// Ошибка сервиса сессии (удаление аккаунта и т.п.)
public struct ProfileSessionError: Error, Sendable, LocalizedError {
    public let message: String
    public init(_ message: String) { self.message = message }
    public var errorDescription: String? { message }
}

/// Сервис выхода и удаления аккаунта (реализуется в приложении, чтобы не тянуть NetworkService в модуль профиля).
public protocol ProfileSessionService: Sendable {
    func clearTokens() async
    func deleteAccount(password: String) async -> Result<Void, ProfileSessionError>
}

public actor ProfileEffectHandler: EffectHandler {
    public typealias S = ProfileState
    
    private let userDefaults = UserDefaults.standard
    private let userKey = "user_profile"
    private let settingsKey = "app_settings"
    private let statisticsKey = "user_statistics"
    private let sessionService: (any ProfileSessionService)?
    
    public init(sessionService: (any ProfileSessionService)? = nil) {
        self.sessionService = sessionService
    }
    
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
            
        case let .performDeleteAccount(password):
            return await performDeleteAccount(password: password)
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
        await sessionService?.clearTokens()
        userDefaults.removeObject(forKey: userKey)
        userDefaults.removeObject(forKey: statisticsKey)
        userDefaults.set(false, forKey: "isOnboardingCompleted")
        return .logoutCompleted
    }
    
    private func performDeleteAccount(password: String) async -> ProfileState.Feedback {
        guard let sessionService = sessionService else {
            return .deleteAccountFailed("Сервис недоступен")
        }
        let result = await sessionService.deleteAccount(password: password)
        switch result {
        case .success:
            userDefaults.removeObject(forKey: userKey)
            userDefaults.removeObject(forKey: statisticsKey)
            userDefaults.removeObject(forKey: settingsKey)
            userDefaults.removeObject(forKey: "calendar_events")
            userDefaults.removeObject(forKey: "caldav_settings")
            userDefaults.set(false, forKey: "isOnboardingCompleted")
            return .accountDeleted
        case .failure(let error):
            return .deleteAccountFailed(error.message)
        }
    }
    
}
