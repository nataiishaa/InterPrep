//
//  ProfileState.swift
//  InterPrep
//
//  Profile feature state
//

import Foundation
import ArchitectureCore

public struct ProfileState {
    public var user: User?
    public var isLoading: Bool = false
    public var errorMessage: String?
    
    // Statistics
    public var statistics: Statistics = Statistics()
    
    // Settings
    public var settings: AppSettings = AppSettings()
    
    // Edit mode
    public var isEditingProfile: Bool = false
    public var editedFirstName: String = ""
    public var editedLastName: String = ""
    public var editedEmail: String = ""
    public var editedPhone: String = ""
    public var editedPosition: String = ""
    public var editedExperience: String = ""
    
    // Resume
    public var resumePDFURL: URL?
    public var isDownloadingResume: Bool = false
    
    // Interviews
    public var selectedInterviewTab: InterviewTab = .upcoming
    public var upcomingInterviews: [Interview] = []
    public var completedInterviews: [Interview] = []
    public var isLoadingInterviews: Bool = false
    
    public var authRequired: Bool = false
    public var deleteAccountError: String?
    
    public var cachedProfilePhotoURL: URL?
    
    public init() {}
}

// MARK: - Models

extension ProfileState {
    public struct User: Codable, Equatable, Sendable {
        public var id: String
        public var firstName: String
        public var lastName: String
        public var email: String
        public var phone: String?
        public var avatarURL: String?
        public var position: String?
        public var experience: String?
        public var resumeUploaded: Bool = false
        /// Не отдаётся бэкендом — только для локального кэша при необходимости
        public var registeredDate: Date?
        
        public var fullName: String {
            "\(firstName) \(lastName)"
        }
        
        public var initials: String {
            let first = firstName.prefix(1)
            let last = lastName.prefix(1)
            let s = "\(first)\(last)".uppercased()
            return s.trimmingCharacters(in: .whitespaces).isEmpty ? "?" : s
        }
        
        public init(id: String, firstName: String, lastName: String, email: String, phone: String? = nil, avatarURL: String? = nil, position: String? = nil, experience: String? = nil, resumeUploaded: Bool = false, registeredDate: Date? = nil) {
            self.id = id
            self.firstName = firstName
            self.lastName = lastName
            self.email = email
            self.phone = phone
            self.avatarURL = avatarURL
            self.position = position
            self.experience = experience
            self.resumeUploaded = resumeUploaded
            self.registeredDate = registeredDate
        }
        
        public init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            id = try c.decode(String.self, forKey: .id)
            firstName = try c.decode(String.self, forKey: .firstName)
            lastName = try c.decode(String.self, forKey: .lastName)
            email = try c.decode(String.self, forKey: .email)
            phone = try c.decodeIfPresent(String.self, forKey: .phone)
            avatarURL = try c.decodeIfPresent(String.self, forKey: .avatarURL)
            position = try c.decodeIfPresent(String.self, forKey: .position)
            experience = try c.decodeIfPresent(String.self, forKey: .experience)
            resumeUploaded = try c.decodeIfPresent(Bool.self, forKey: .resumeUploaded) ?? false
            registeredDate = try c.decodeIfPresent(Date.self, forKey: .registeredDate)
        }
        
        private enum CodingKeys: String, CodingKey {
            case id, firstName, lastName, email, phone, avatarURL, position, experience, resumeUploaded, registeredDate
        }
    }
    
    public struct Statistics: Codable, Equatable, Sendable {
        public var totalInterviews: Int = 0
        public var completedInterviews: Int = 0
        public var upcomingInterviews: Int = 0
        public var totalApplications: Int = 0
        public var responseRate: Double = 0.0
        public var averagePreparationTime: TimeInterval = 0
        
        public var successRate: Double {
            guard totalInterviews > 0 else { return 0 }
            return Double(completedInterviews) / Double(totalInterviews) * 100
        }
        
        public init(totalInterviews: Int = 0, completedInterviews: Int = 0, upcomingInterviews: Int = 0, totalApplications: Int = 0, responseRate: Double = 0.0, averagePreparationTime: TimeInterval = 0) {
            self.totalInterviews = totalInterviews
            self.completedInterviews = completedInterviews
            self.upcomingInterviews = upcomingInterviews
            self.totalApplications = totalApplications
            self.responseRate = responseRate
            self.averagePreparationTime = averagePreparationTime
        }
    }
    
    public enum InterviewTab: String, CaseIterable, Sendable {
        case upcoming = "Запланировано"
        case completed = "Прошло"
    }
    
    public struct Interview: Identifiable, Codable, Equatable, Sendable {
        public let id: String
        public let title: String
        public let company: String
        public let date: Date
        public let type: String
        public let isCompleted: Bool
        
        public init(id: String, title: String, company: String, date: Date, type: String, isCompleted: Bool) {
            self.id = id
            self.title = title
            self.company = company
            self.date = date
            self.type = type
            self.isCompleted = isCompleted
        }
    }
    
    public struct AppSettings: Codable, Equatable, Sendable {
        // Notifications
        public var notificationsEnabled: Bool = true
        public var reminderTime: Int = 30 // minutes before
        public var emailNotifications: Bool = true
        
        // Appearance
        public var theme: Theme = .system
        public var language: Language = .russian
        
        // Privacy
        public var analyticsEnabled: Bool = true
        public var crashReportsEnabled: Bool = true
        
        // CalDAV
        public var calDAVEnabled: Bool = false
        
        public init(notificationsEnabled: Bool = true, reminderTime: Int = 30, emailNotifications: Bool = true, theme: Theme = .system, language: Language = .russian, analyticsEnabled: Bool = true, crashReportsEnabled: Bool = true, calDAVEnabled: Bool = false) {
            self.notificationsEnabled = notificationsEnabled
            self.reminderTime = reminderTime
            self.emailNotifications = emailNotifications
            self.theme = theme
            self.language = language
            self.analyticsEnabled = analyticsEnabled
            self.crashReportsEnabled = crashReportsEnabled
            self.calDAVEnabled = calDAVEnabled
        }
        
        public enum Theme: String, Codable, CaseIterable, Sendable {
            case light = "Светлая"
            case dark = "Темная"
            case system = "Системная"
        }
        
        public enum Language: String, Codable, CaseIterable, Sendable {
            case russian = "Русский"
            case english = "English"
        }
    }
}

// MARK: - FeatureState

extension ProfileState: FeatureState {
    public enum Input: Sendable {
        case onAppear
        case refresh
        
        // Profile editing
        case startEditingProfile
        case cancelEditingProfile
        case firstNameChanged(String)
        case lastNameChanged(String)
        case saveProfile
        
        // Interviews
        case interviewTabChanged(InterviewTab)
        case loadInterviews
        case interviewTapped(Interview)
        
        // Settings
        case notificationsToggled(Bool)
        case reminderTimeChanged(Int)
        case emailNotificationsToggled(Bool)
        case themeChanged(AppSettings.Theme)
        case languageChanged(AppSettings.Language)
        case analyticsToggled(Bool)
        case crashReportsToggled(Bool)
        
        // Actions
        case viewResume
        case changeResume
        case logout
        case deleteAccount(password: String)
        case clearAuthRequired
        case clearDeleteAccountError
        case openCalDAVSettings
        case uploadProfilePhoto(Data)
    }
    
    public enum Feedback: Sendable {
        case userLoaded(User)
        case statisticsLoaded(Statistics)
        /// Профиль и статистика загружены с бэкенда (getMe). profilePhotoURL — локальный URL кеша, если фото загружено.
        case profileLoaded(user: User, statistics: Statistics, profilePhotoURL: URL?)
        case profilePhotoUpdated(URL)
        case profileUpdated(User)
        case settingsSaved
        case loadingFailed(String)
        case logoutCompleted
        case accountDeleted
        case deleteAccountFailed(String)
        case resumeDownloaded(URL)
        case resumeDownloadFailed(String)
        case interviewsLoaded(upcoming: [Interview], completed: [Interview])
        case interviewsLoadFailed(String)
    }
    
    public enum Effect: Sendable {
        case loadUser
        case loadStatistics
        case updateProfile(User)
        case saveSettings(AppSettings)
        case downloadResume
        case navigateToResumeUpload
        case performLogout
        case performDeleteAccount(password: String)
        case loadInterviews
        case navigateToInterview(Interview)
        case uploadProfilePhoto(userId: String, data: Data)
    }
    
    @MainActor
    public static func reduce(
        state: inout Self,
        with message: Message<Input, Feedback>
    ) -> Effect? {
        switch message {
        case .input(.onAppear), .input(.refresh):
            state.isLoading = true
            state.isLoadingInterviews = true
            return .loadUser
            
        // Profile editing
        case .input(.startEditingProfile):
            state.isEditingProfile = true
            if let user = state.user {
                state.editedFirstName = user.firstName
                state.editedLastName = user.lastName
            }
            
        case .input(.cancelEditingProfile):
            state.isEditingProfile = false
            state.errorMessage = nil
            
        case let .input(.firstNameChanged(name)):
            state.editedFirstName = name
            state.errorMessage = nil
            
        case let .input(.lastNameChanged(name)):
            state.editedLastName = name
            state.errorMessage = nil
            
        case .input(.saveProfile):
            guard !state.editedFirstName.isEmpty,
                  !state.editedLastName.isEmpty else {
                state.errorMessage = "Заполните имя и фамилию"
                return nil
            }
            
            guard let user = state.user else { return nil }
            
            let updatedUser = User(
                id: user.id,
                firstName: state.editedFirstName,
                lastName: state.editedLastName,
                email: user.email,
                phone: user.phone,
                avatarURL: user.avatarURL,
                position: user.position,
                experience: user.experience,
                registeredDate: user.registeredDate ?? nil
            )
            
            state.isLoading = true
            return .updateProfile(updatedUser)
            
        // Settings
        case let .input(.notificationsToggled(enabled)):
            state.settings.notificationsEnabled = enabled
            return .saveSettings(state.settings)
            
        case let .input(.reminderTimeChanged(minutes)):
            state.settings.reminderTime = minutes
            return .saveSettings(state.settings)
            
        case let .input(.emailNotificationsToggled(enabled)):
            state.settings.emailNotifications = enabled
            return .saveSettings(state.settings)
            
        case let .input(.themeChanged(theme)):
            state.settings.theme = theme
            return .saveSettings(state.settings)
            
        case let .input(.languageChanged(language)):
            state.settings.language = language
            return .saveSettings(state.settings)
            
        case let .input(.analyticsToggled(enabled)):
            state.settings.analyticsEnabled = enabled
            return .saveSettings(state.settings)
            
        case let .input(.crashReportsToggled(enabled)):
            state.settings.crashReportsEnabled = enabled
            return .saveSettings(state.settings)
            
        // Actions
        case .input(.viewResume):
            state.isDownloadingResume = true
            state.errorMessage = nil
            return .downloadResume
            
        case .input(.changeResume):
            return .navigateToResumeUpload
            
        case .input(.logout):
            return .performLogout
            
        case let .input(.deleteAccount(password)):
            state.deleteAccountError = nil
            return .performDeleteAccount(password: password)
            
        case .input(.clearAuthRequired):
            state.authRequired = false
            return nil
            
        case .input(.clearDeleteAccountError):
            state.deleteAccountError = nil
            return nil
            
        case .input(.openCalDAVSettings):
            // Handled in UI
            break
            
        case let .input(.uploadProfilePhoto(data)):
            guard let userId = state.user?.id else { return nil }
            return .uploadProfilePhoto(userId: userId, data: data)
            
        // Interviews
        case let .input(.interviewTabChanged(tab)):
            state.selectedInterviewTab = tab
            
        case .input(.loadInterviews):
            state.isLoadingInterviews = true
            return .loadInterviews
            
        case let .input(.interviewTapped(interview)):
            return .navigateToInterview(interview)
            
        // Feedback
        case let .feedback(.userLoaded(user)):
            state.isLoading = false
            state.user = user
            state.isLoadingInterviews = true
            return .loadStatistics
            
        case let .feedback(.statisticsLoaded(statistics)):
            state.statistics = statistics
            return .loadInterviews
            
        case let .feedback(.profileLoaded(user, statistics, profilePhotoURL)):
            state.isLoading = false
            state.user = user
            state.statistics = statistics
            state.cachedProfilePhotoURL = profilePhotoURL
            return nil
            
        case let .feedback(.profilePhotoUpdated(url)):
            state.cachedProfilePhotoURL = url
            return nil
            
        case let .feedback(.profileUpdated(user)):
            state.isLoading = false
            state.isEditingProfile = false
            state.user = user
            
        case .feedback(.settingsSaved):
            // Settings saved successfully
            break
            
        case let .feedback(.loadingFailed(error)):
            state.isLoading = false
            state.errorMessage = error
            
        case .feedback(.logoutCompleted):
            state.user = nil
            state.statistics = Statistics()
            state.authRequired = true
            
        case .feedback(.accountDeleted):
            state.user = nil
            state.statistics = Statistics()
            state.settings = AppSettings()
            state.authRequired = true
            
        case let .feedback(.deleteAccountFailed(message)):
            state.deleteAccountError = message
            
        case let .feedback(.resumeDownloaded(url)):
            state.isDownloadingResume = false
            state.resumePDFURL = url
            
        case let .feedback(.resumeDownloadFailed(error)):
            state.isDownloadingResume = false
            state.errorMessage = error
            
        case let .feedback(.interviewsLoaded(upcoming, completed)):
            state.isLoadingInterviews = false
            state.upcomingInterviews = upcoming
            state.completedInterviews = completed
            
        case let .feedback(.interviewsLoadFailed(error)):
            state.isLoadingInterviews = false
            state.errorMessage = error
        }
        
        return nil
    }
}
