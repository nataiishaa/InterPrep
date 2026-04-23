//
//  CalDAVSettings.swift
//  InterPrep
//
//  CalDAV connection settings
//

import Foundation

public struct CalDAVSettings: Codable {
    public var isEnabled: Bool = false
    public var serverURL: String = ""
    public var username: String = ""
    public var password: String = "" // Should be stored in Keychain in production
    public var selectedCalendarURL: String?
    public var lastSyncDate: Date?
    
    public init(
        isEnabled: Bool = false,
        serverURL: String = "",
        username: String = "",
        password: String = "",
        selectedCalendarURL: String? = nil,
        lastSyncDate: Date? = nil
    ) {
        self.isEnabled = isEnabled
        self.serverURL = serverURL
        self.username = username
        self.password = password
        self.selectedCalendarURL = selectedCalendarURL
        self.lastSyncDate = lastSyncDate
    }
    
    public static let presets: [CalDAVPreset] = [
        .init(
            name: "Google Calendar",
            serverURL: "https://apidata.googleusercontent.com/caldav/v2/",
            instructions: "Имя пользователя — ваш email в Google. Пароль: в аккаунте Google откройте Безопасность → Пароли приложений, создайте пароль и введите его здесь (не основной пароль от почты)."
        ),
        .init(
            name: "iCloud",
            serverURL: "https://caldav.icloud.com/",
            instructions: "Имя пользователя — ваш Apple ID (email). Пароль: Настройки → Apple ID → Вход и безопасность → Пароли приложений — создайте пароль для «Другое» и введите его здесь."
        ),
        .init(
            name: "Nextcloud",
            serverURL: "https://your-server.com/remote.php/dav/",
            instructions: "Укажите адрес вашего Nextcloud (например https://cloud.example.com/remote.php/dav/). Имя и пароль — от вашего аккаунта Nextcloud."
        ),
        .init(
            name: "Другой календарь",
            serverURL: "",
            instructions: "Если ваш календарь поддерживает CalDAV, уточните у провайдера URL сервера и введите его, а также логин и пароль."
        )
    ]
}

public struct CalDAVPreset {
    public let name: String
    public let serverURL: String
    public let instructions: String
    
    public init(name: String, serverURL: String, instructions: String) {
        self.name = name
        self.serverURL = serverURL
        self.instructions = instructions
    }
}

public final class CalDAVSettingsManager {
    public static let shared = CalDAVSettingsManager()
    
    private let userDefaults = UserDefaults.standard
    private let settingsKey = "caldav_settings"
    
    private init() {}
    
    public func loadSettings() -> CalDAVSettings {
        guard let data = userDefaults.data(forKey: settingsKey),
              let settings = try? JSONDecoder().decode(CalDAVSettings.self, from: data) else {
            return CalDAVSettings()
        }
        return settings
    }
    
    public func saveSettings(_ settings: CalDAVSettings) {
        if let data = try? JSONEncoder().encode(settings) {
            userDefaults.set(data, forKey: settingsKey)
        }
    }
    
    func createClient(from settings: CalDAVSettings) -> CalDAVClient? {
        guard settings.isEnabled,
              let url = URL(string: settings.serverURL),
              !settings.username.isEmpty,
              !settings.password.isEmpty else {
            return nil
        }
        
        return CalDAVClient(
            serverURL: url,
            username: settings.username,
            password: settings.password
        )
    }
}
