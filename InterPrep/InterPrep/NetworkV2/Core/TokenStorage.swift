import Foundation

public actor TokenStorage {
    private var accessToken: String?
    private var refreshToken: String?
    
    private let accessTokenKey = "com.interprep.access_token"
    private let refreshTokenKey = "com.interprep.refresh_token"
    
    public init() {
        self.accessToken = UserDefaults.standard.string(forKey: accessTokenKey)
        self.refreshToken = UserDefaults.standard.string(forKey: refreshTokenKey)
    }
    
    public func setTokens(accessToken: String, refreshToken: String) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        UserDefaults.standard.set(accessToken, forKey: accessTokenKey)
        UserDefaults.standard.set(refreshToken, forKey: refreshTokenKey)
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
        UserDefaults.standard.removeObject(forKey: accessTokenKey)
        UserDefaults.standard.removeObject(forKey: refreshTokenKey)
    }
    
    public func hasValidTokens() -> Bool {
        return accessToken != nil && refreshToken != nil
    }
}
