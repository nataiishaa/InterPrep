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
    
    // Predefined servers
    public static let presets: [CalDAVPreset] = [
        .init(
            name: "Google Calendar",
            serverURL: "https://apidata.googleusercontent.com/caldav/v2/",
            instructions: "Используйте пароль приложения из настроек Google"
        ),
        .init(
            name: "iCloud",
            serverURL: "https://caldav.icloud.com/",
            instructions: "Используйте пароль приложения из настроек Apple ID"
        ),
        .init(
            name: "Nextcloud",
            serverURL: "https://your-server.com/remote.php/dav/",
            instructions: "Введите URL вашего Nextcloud сервера"
        ),
        .init(
            name: "Другой сервер",
            serverURL: "",
            instructions: "Введите URL CalDAV сервера вручную"
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

// MARK: - Settings Manager

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
