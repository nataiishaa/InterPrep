//
//  ProfileEffectHandler.swift
//  InterPrep
//
//  Profile effect handler
//

import ArchitectureCore
import CacheService
import DesignSystem
import Foundation
import NetworkMonitorService
import NetworkService
import NotificationService
import SwiftUI

public struct ProfileSessionError: Error, Sendable, LocalizedError {
    public let message: String
    public init(_ message: String) { self.message = message }
    public var errorDescription: String? { message }
}

public protocol ProfileSessionService: Sendable {
    func clearTokens() async
    func deleteAccount(password: String) async -> Result<Void, ProfileSessionError>
}

public actor ProfileEffectHandler: EffectHandler {
    public typealias StateType = ProfileState
    
    private let userDefaults = UserDefaults.standard
    private let cacheManager = CacheManager.shared
    
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
            
        case .loadResumeInfo:
            return await loadResumeInfo()
            
        case let .updateProfile(user):
            return await updateProfile(user)
            
        case let .saveSettings(settings):
            return await saveSettings(settings)
            
        case .downloadResume:
            return await downloadResume()
            
        case .navigateToResumeUpload:
            return nil
            
        case .performLogout:
            return await performLogout()
            
        case let .performDeleteAccount(password):
            return await performDeleteAccount(password: password)
            
        case .loadInterviews:
            return await loadInterviews()
            
        case .navigateToInterview:
            return nil
            
        case let .uploadProfilePhoto(userId, data):
            return await uploadProfilePhoto(userId: userId, data: data)
        }
    }
    
    private func loadResumeInfo() async -> ProfileState.Feedback {
        let result = await NetworkServiceV2.shared.getUser_ResumeProfile()
        switch result {
        case .success(let response):
            let hasData = response.hasProfile || (response.hasSourceMaterialID && !response.sourceMaterialID.isEmpty)
            let materialId = response.hasSourceMaterialID ? response.sourceMaterialID : nil
            return .resumeInfoLoaded(hasData: hasData, sourceMaterialId: materialId)
            
        case .failure:
            return .resumeInfoLoaded(hasData: false, sourceMaterialId: nil)
        }
    }
    
    private func loadUser() async -> ProfileState.Feedback {
        await loadAndApplyTheme()
        
        let result = await NetworkServiceV2.shared.getMe()
        switch result {
        case .success(let response):
            let userProto = response.user
            let user = ProfileState.User(
                id: String(userProto.id),
                firstName: userProto.firstName,
                lastName: userProto.lastName,
                email: userProto.email,
                phone: nil,
                avatarURL: nil,
                position: nil,
                experience: nil,
                resumeUploaded: userProto.resumeUploaded,
                registeredDate: nil
            )
            let statistics = ProfileState.Statistics(
                totalInterviews: Int(userProto.totalInterviews),
                completedInterviews: Int(userProto.completedInterviews),
                upcomingInterviews: Int(userProto.upcomingInterviews),
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
            try? await cacheManager.save(user, forKey: CacheKey.profileUser)
            try? await cacheManager.save(statistics, forKey: CacheKey.profileStatistics)
            
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
                return .profileLoadedFromCache(user: user, statistics: statistics, profilePhotoURL: photoURL)
            }
            if let userData = userDefaults.data(forKey: userKey),
               let user = try? JSONDecoder().decode(ProfileState.User.self, from: userData) {
                let photoURL = Self.profilePhotoCachedURL(userId: user.id)
                return .profileLoadedFromCache(user: user, statistics: ProfileState.Statistics(), profilePhotoURL: photoURL)
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
            return .profileLoadedFromCache(user: defaultUser, statistics: ProfileState.Statistics(), profilePhotoURL: nil)
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
        let sizeKB = Double(data.count) / 1024.0
        print("[ProfilePhoto] uploading \(String(format: "%.1f", sizeKB)) KB for userId=\(userId)")
        let result = await NetworkServiceV2.shared.uploadProfilePhoto(imageData: data, filename: "photo.jpg", mimeType: "image/jpeg")
        switch result {
        case .success(let response):
            print("[ProfilePhoto] upload success, ok=\(response.ok)")
            guard response.ok else {
                return .loadingFailed("Сервер отклонил фото. Попробуйте другое изображение")
            }
            Self.profilePhotoSaveSync(userId: userId, data: data)
            if let baseURL = Self.profilePhotoCacheFileURL(userId: userId) {
                var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)
                components?.queryItems = [URLQueryItem(name: "t", value: String(Date().timeIntervalSince1970))]
                let url = components?.url ?? baseURL
                return .profilePhotoUpdated(url)
            }
            return nil
        case .failure(let error):
            print("[ProfilePhoto] upload FAILED: type=\(type(of: error)) error=\(error)")
            if case .transportError(let underlying) = error {
                print("[ProfilePhoto] transport underlying: type=\(type(of: underlying)) desc=\(String(describing: underlying))")
            }
            if case .apiError(let apiErr) = error {
                print("[ProfilePhoto] apiError: code=\(apiErr.code) msg=\(apiErr.serverMessage)")
                if apiErr.code == .internalError {
                    return .loadingFailed("Ошибка сервера при загрузке фото. Попробуйте позже")
                }
            }
            if error.isConnectionError {
                return .loadingFailed("Ошибка соединения. Проверьте интернет и попробуйте снова")
            }
            let desc = error.localizedDescription
            let message = desc.isEmpty ? "Не удалось загрузить фото" : "Не удалось загрузить фото: \(desc)"
            return .loadingFailed(message)
        }
    }
    
    private func loadStatistics() async -> ProfileState.Feedback {
        do {
            if let data = userDefaults.data(forKey: statisticsKey) {
                let statistics = try JSONDecoder().decode(ProfileState.Statistics.self, from: data)
                return .statisticsLoaded(statistics)
            } else {
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
                try? await cacheManager.save(user, forKey: CacheKey.profileUser)
                return .profileUpdated(user)
            } catch {
                return .loadingFailed("Не удалось сохранить профиль")
            }
        case .failure(let error):
            if (error as? NetworkError)?.isConnectionError == true {
                do {
                    let data = try JSONEncoder().encode(user)
                    userDefaults.set(data, forKey: userKey)
                    try? await cacheManager.save(user, forKey: CacheKey.profileUser)
                    
                    await MainActor.run {
                        OfflineSyncManager.shared.addOperation(.updateProfile(
                            firstName: user.firstName,
                            lastName: user.lastName
                        ))
                    }
                    
                    return .profileUpdated(user)
                } catch {
                    return .loadingFailed("Не удалось сохранить профиль")
                }
            }
            return .loadingFailed(error.localizedDescription)
        }
    }
    
    private func saveSettings(_ settings: ProfileState.AppSettings) async -> ProfileState.Feedback {
        do {
            let data = try JSONEncoder().encode(settings)
            userDefaults.set(data, forKey: settingsKey)
            
            await applyTheme(settings.theme)
            await applyNotificationSettings(settings.notificationsEnabled)
            
            return .settingsSaved
        } catch {
            return .loadingFailed("Не удалось сохранить настройки")
        }
    }
    
    @MainActor
    private func applyNotificationSettings(_ enabled: Bool) async {
        NotificationManager.shared.isEnabled = enabled
        
        if enabled && !NotificationManager.shared.isAuthorized {
            _ = await NotificationManager.shared.requestAuthorization()
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
            
            upcoming.sort { $0.date < $1.date }
            completed.sort { $0.date > $1.date }
            
            try? await cacheManager.save(upcoming, forKey: CacheKey.profileInterviewsUpcoming)
            try? await cacheManager.save(completed, forKey: CacheKey.profileInterviewsCompleted)
            
            return .interviewsLoaded(upcoming: upcoming, completed: completed)
            
        case .failure:
            if let cachedUpcoming = try? await cacheManager.load(forKey: CacheKey.profileInterviewsUpcoming, as: [ProfileState.Interview].self),
               let cachedCompleted = try? await cacheManager.load(forKey: CacheKey.profileInterviewsCompleted, as: [ProfileState.Interview].self) {
                return .interviewsLoadedFromCache(upcoming: cachedUpcoming, completed: cachedCompleted)
            }
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
