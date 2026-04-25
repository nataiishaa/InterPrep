import Foundation
import Security

public actor TokenStorage {
    private var accessToken: String?
    private var refreshToken: String?
    
    private let accessTokenKey = "com.interprep.access_token"
    private let refreshTokenKey = "com.interprep.refresh_token"
    private let service = "com.interprep.app"
    
    public init() {
        self.accessToken = loadFromKeychain(key: accessTokenKey)
        self.refreshToken = loadFromKeychain(key: refreshTokenKey)
        
        migrateFromUserDefaults()
    }
    
    public func setTokens(accessToken: String, refreshToken: String) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        saveToKeychain(key: accessTokenKey, value: accessToken)
        saveToKeychain(key: refreshTokenKey, value: refreshToken)
    }
    
    public func getAccessToken() -> String? {
        return accessToken
    }
    
    public func getRefreshToken() -> String? {
        return refreshToken
    }
    
    public func clearTokens() {
        self.accessToken = nil
        self.refreshToken = nil
        deleteFromKeychain(key: accessTokenKey)
        deleteFromKeychain(key: refreshTokenKey)
    }
    
    public func hasValidTokens() -> Bool {
        return accessToken != nil && refreshToken != nil
    }
    
    /// Synchronous Keychain check — safe to call outside actor context (e.g. from AppCoordinator.init).
    public static func hasStoredTokensInKeychain() -> Bool {
        let service = "com.interprep.app"
        func exists(_ account: String) -> Bool {
            let query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: service,
                kSecAttrAccount as String: account,
                kSecReturnData as String: true,
                kSecMatchLimit as String: kSecMatchLimitOne
            ]
            var result: AnyObject?
            return SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess
        }
        return exists("com.interprep.access_token") && exists("com.interprep.refresh_token")
    }
    
    private func saveToKeychain(key: String, value: String) {
        guard let data = value.data(using: .utf8) else { return }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]
        
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }
    
    private func loadFromKeychain(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data,
              let value = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        return value
    }
    
    private func deleteFromKeychain(key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        
        SecItemDelete(query as CFDictionary)
    }
    
    private func migrateFromUserDefaults() {
        if let oldAccessToken = UserDefaults.standard.string(forKey: accessTokenKey),
           let oldRefreshToken = UserDefaults.standard.string(forKey: refreshTokenKey),
           self.accessToken == nil {
            saveToKeychain(key: accessTokenKey, value: oldAccessToken)
            saveToKeychain(key: refreshTokenKey, value: oldRefreshToken)
            self.accessToken = oldAccessToken
            self.refreshToken = oldRefreshToken
            
            UserDefaults.standard.removeObject(forKey: accessTokenKey)
            UserDefaults.standard.removeObject(forKey: refreshTokenKey)
        }
    }
}
