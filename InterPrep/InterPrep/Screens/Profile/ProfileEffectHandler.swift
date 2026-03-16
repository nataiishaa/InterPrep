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
import NetworkService

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
    
    private static func profilePhotoCacheFileURL(userId: String) -> URL? {
        guard let dir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first?
            .appendingPathComponent("ProfilePhotos", isDirectory: true) else { return nil }
        let safe = userId.filter { $0.isLetter || $0.isNumber }.isEmpty ? "default" : userId.filter { $0.isLetter || $0.isNumber }
        return dir.appendingPathComponent("\(safe).jpg", isDirectory: false)
    }
    
    private static func profilePhotoCachedURL(userId: String) -> URL? {
        guard let url = profilePhotoCacheFileURL(userId: userId),
              FileManager.default.fileExists(atPath: url.path) else { return nil }
        return url
    }
    
    private static func profilePhotoSaveSync(userId: String, data: Data) {
        guard let dir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first?
                .appendingPathComponent("ProfilePhotos", isDirectory: true),
              let fileURL = profilePhotoCacheFileURL(userId: userId) else { return }
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        try? data.write(to: fileURL)
    }
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
            
        case .downloadResume:
            return await downloadResume()
            
        case .navigateToResumeUpload:
            // Navigation handled by coordinator
            return nil
            
        case .performLogout:
            return await performLogout()
            
        case let .performDeleteAccount(password):
            return await performDeleteAccount(password: password)
            
        case .loadInterviews:
            return await loadInterviews()
            
        case .navigateToInterview:
            // Navigation handled by coordinator
            return nil
            
        case let .uploadProfilePhoto(userId, data):
            return await uploadProfilePhoto(userId: userId, data: data)
        }
    }
    
    // MARK: - Private Methods
    
    private func loadUser() async -> ProfileState.Feedback {
        await loadAndApplyTheme()
        
        let result = await NetworkServiceV2.shared.getMe()
        switch result {
        case .success(let response):
            let u = response.user
            let user = ProfileState.User(
                id: String(u.id),
                firstName: u.firstName,
                lastName: u.lastName,
                email: u.email,
                phone: nil,
                avatarURL: nil,
                position: nil,
                experience: nil,
                resumeUploaded: u.resumeUploaded,
                registeredDate: nil
            )
            let statistics = ProfileState.Statistics(
                totalInterviews: Int(u.totalInterviews),
                completedInterviews: Int(u.completedInterviews),
                upcomingInterviews: Int(u.upcomingInterviews),
                totalApplications: 0,
                responseRate: 0,
                averagePreparationTime: 0
            )
            if let data = try? JSONEncoder().encode(user) {
                userDefaults.set(data, forKey: userKey)
            }
            if let data = try? JSONEncoder().encode(statistics) {
                userDefaults.set(data, forKey: statisticsKey)
            }
            var profilePhotoURL: URL? = Self.profilePhotoCachedURL(userId: user.id)
            if profilePhotoURL == nil {
                let photoResult = await NetworkServiceV2.shared.getProfilePhoto()
                if case .success(let resp) = photoResult, !resp.content.isEmpty {
                    Self.profilePhotoSaveSync(userId: user.id, data: resp.content)
                    profilePhotoURL = Self.profilePhotoCacheFileURL(userId: user.id)
                }
            }
            return .profileLoaded(user: user, statistics: statistics, profilePhotoURL: profilePhotoURL)
            
        case .failure:
            break
        }
        
        do {
            if let userData = userDefaults.data(forKey: userKey),
               let user = try? JSONDecoder().decode(ProfileState.User.self, from: userData),
               let statData = userDefaults.data(forKey: statisticsKey),
               let statistics = try? JSONDecoder().decode(ProfileState.Statistics.self, from: statData) {
                let photoURL = Self.profilePhotoCachedURL(userId: user.id)
                return .profileLoaded(user: user, statistics: statistics, profilePhotoURL: photoURL)
            }
            if let userData = userDefaults.data(forKey: userKey),
               let user = try? JSONDecoder().decode(ProfileState.User.self, from: userData) {
                let photoURL = Self.profilePhotoCachedURL(userId: user.id)
                return .profileLoaded(user: user, statistics: ProfileState.Statistics(), profilePhotoURL: photoURL)
            }
            let defaultUser = ProfileState.User(
                id: "",
                firstName: "Пользователь",
                lastName: "",
                email: "",
                phone: nil,
                avatarURL: nil,
                position: nil,
                experience: nil,
                resumeUploaded: false,
                registeredDate: nil
            )
            let data = try JSONEncoder().encode(defaultUser)
            userDefaults.set(data, forKey: userKey)
            return .profileLoaded(user: defaultUser, statistics: ProfileState.Statistics(), profilePhotoURL: nil)
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
    
    private func uploadProfilePhoto(userId: String, data: Data) async -> ProfileState.Feedback? {
        guard !data.isEmpty else {
            return .loadingFailed("Выберите изображение")
        }
        let result = await NetworkServiceV2.shared.uploadProfilePhoto(imageData: data, filename: "photo.jpg", mimeType: "image/jpeg")
        switch result {
        case .success:
            Self.profilePhotoSaveSync(userId: userId, data: data)
            if let url = Self.profilePhotoCacheFileURL(userId: userId) {
                return .profilePhotoUpdated(url)
            }
            return nil
        case .failure(let error):
            let message = error.localizedDescription.isEmpty ? "Не удалось загрузить фото" : "Не удалось загрузить фото: \(error.localizedDescription)"
            return .loadingFailed(message)
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
        let result = await NetworkServiceV2.shared.updateUserProfile(
            firstName: user.firstName,
            lastName: user.lastName,
            email: nil,
            notificationsEnabled: nil
        )
        switch result {
        case .success:
            do {
                let data = try JSONEncoder().encode(user)
                userDefaults.set(data, forKey: userKey)
                return .profileUpdated(user)
            } catch {
                return .loadingFailed("Не удалось сохранить профиль")
            }
        case .failure(let error):
            return .loadingFailed(error.localizedDescription)
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
    
    private func downloadResume() async -> ProfileState.Feedback {
        let profileResult = await NetworkServiceV2.shared.getUser_ResumeProfile()
        
        switch profileResult {
        case .success(let response):
            guard response.hasSourceMaterialID, !response.sourceMaterialID.isEmpty else {
                return .resumeDownloadFailed("Резюме еще не загружено. Пожалуйста, загрузите резюме сначала.")
            }
            
            let materialId = response.sourceMaterialID
            let downloadResult = await NetworkServiceV2.shared.downloadFile(materialId: materialId)
            
            switch downloadResult {
            case .success(let downloadResponse):
                let tempDir = FileManager.default.temporaryDirectory
                let fileName = downloadResponse.filename.isEmpty ? "resume.pdf" : downloadResponse.filename
                let fileURL = tempDir.appendingPathComponent(fileName)
                
                do {
                    try downloadResponse.content.write(to: fileURL)
                    return .resumeDownloaded(fileURL)
                } catch {
                    return .resumeDownloadFailed("Не удалось сохранить файл")
                }
                
            case .failure:
                return .resumeDownloadFailed("Не удалось скачать резюме")
            }
            
        case .failure:
            return .resumeDownloadFailed("Не удалось получить информацию о резюме")
        }
    }
    
    private func loadInterviews() async -> ProfileState.Feedback {
        let result = await NetworkServiceV2.shared.listUpcoming(limit: 100, fromTime: Date())
        
        switch result {
        case .success(let response):
            let now = Date()
            var upcoming: [ProfileState.Interview] = []
            var completed: [ProfileState.Interview] = []
            
            for event in response.events {
                let interview = ProfileState.Interview(
                    id: event.id,
                    title: event.title,
                    company: event.description_p.isEmpty ? "Компания" : event.description_p,
                    date: event.startTime.date,
                    type: eventTypeToString(event.eventType),
                    isCompleted: event.completed
                )
                
                if event.completed || interview.date < now {
                    completed.append(interview)
                } else {
                    upcoming.append(interview)
                }
            }
            
            // Sort: upcoming by date ascending, completed by date descending
            upcoming.sort { $0.date < $1.date }
            completed.sort { $0.date > $1.date }
            
            return .interviewsLoaded(upcoming: upcoming, completed: completed)
            
        case .failure:
            return .interviewsLoadFailed("Не удалось загрузить собеседования")
        }
    }
    
    private func eventTypeToString(_ type: Calendar_EventType) -> String {
        switch type {
        case .interview:
            return "Собеседование"
        case .call:
            return "Звонок"
        case .meeting:
            return "Встреча"
        case .testTask:
            return "Тестовое задание"
        case .prep:
            return "Подготовка"
        case .deadline:
            return "Дедлайн"
        case .other:
            return "Другое"
        default:
            return "Событие"
        }
    }
    
}
