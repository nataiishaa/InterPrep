import Foundation
import Security

public struct CalDAVSettings: Codable {
    public var isEnabled: Bool = false
    public var serverURL: String = ""
    public var username: String = ""
    public var password: String = ""
    public var selectedCalendarURL: String?
    public var lastSyncDate: Date?

    private enum CodingKeys: String, CodingKey {
        case isEnabled, serverURL, username, selectedCalendarURL, lastSyncDate
    }

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
            name: "iCloud",
            serverURL: "https://caldav.icloud.com/",
            instructions: "Имя пользователя — ваш Apple ID (email).\n\nПароль: откройте appleid.apple.com → Вход и безопасность → Пароли для приложений → создайте пароль для «Другое» и введите его здесь (не основной пароль от Apple ID)."
        ),
        .init(
            name: "Fastmail",
            serverURL: "https://caldav.fastmail.com/dav/calendars/user/",
            instructions: "Имя пользователя — ваш email в Fastmail.\n\nПароль: Настройки → Пароли и безопасность → Сторонние приложения → создайте пароль для приложения."
        ),
        .init(
            name: "Nextcloud",
            serverURL: "",
            instructions: "Укажите адрес вашего Nextcloud-сервера (например https://cloud.example.com/remote.php/dav/).\n\nИмя и пароль — от вашего аккаунта Nextcloud."
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
    private let keychainService = "com.interprep.caldav"
    private let keychainAccount = "caldav_password"

    private init() {}

    public func loadSettings() -> CalDAVSettings {
        guard let data = userDefaults.data(forKey: settingsKey),
              var settings = try? JSONDecoder().decode(CalDAVSettings.self, from: data) else {
            return CalDAVSettings()
        }
        settings.password = loadPasswordFromKeychain() ?? ""
        return settings
    }

    public func saveSettings(_ settings: CalDAVSettings) {
        if let data = try? JSONEncoder().encode(settings) {
            userDefaults.set(data, forKey: settingsKey)
        }
        if settings.password.isEmpty {
            deletePasswordFromKeychain()
        } else {
            savePasswordToKeychain(settings.password)
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

    private func savePasswordToKeychain(_ password: String) {
        guard let data = password.data(using: .utf8) else { return }
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }

    private func loadPasswordFromKeychain() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data else {
            return nil
        }
        return String(data: data, encoding: .utf8)
    }

    private func deletePasswordFromKeychain() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount
        ]
        SecItemDelete(query as CFDictionary)
    }
}
