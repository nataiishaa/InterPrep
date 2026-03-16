import Foundation

public struct UserProfile: Codable, Identifiable, Sendable {
    public let id: String
    public let firstName: String
    public let lastName: String
    public let email: String
    public let username: String?
    public let resumeUploaded: Bool?
    public let totalInterviews: Int?
    public let completedInterviews: Int?
    public let upcomingInterviews: Int?
    public let notificationsEnabled: Bool?
    
    enum CodingKeys: String, CodingKey {
        case id
        case firstName = "first_name"
        case lastName = "last_name"
        case email
        case username
        case resumeUploaded = "resume_uploaded"
        case totalInterviews = "total_interviews"
        case completedInterviews = "completed_interviews"
        case upcomingInterviews = "upcoming_interviews"
        case notificationsEnabled = "notifications_enabled"
    }
    
    public init(
        id: String,
        firstName: String,
        lastName: String,
        email: String,
        username: String? = nil,
        resumeUploaded: Bool? = nil,
        totalInterviews: Int? = nil,
        completedInterviews: Int? = nil,
        upcomingInterviews: Int? = nil,
        notificationsEnabled: Bool? = nil
    ) {
        self.id = id
        self.firstName = firstName
        self.lastName = lastName
        self.email = email
        self.username = username
        self.resumeUploaded = resumeUploaded
        self.totalInterviews = totalInterviews
        self.completedInterviews = completedInterviews
        self.upcomingInterviews = upcomingInterviews
        self.notificationsEnabled = notificationsEnabled
    }
}

public struct RegisterRequest: Codable, Sendable {
    public let firstName: String
    public let lastName: String
    public let email: String
    public let password: String
    public let deviceId: String?
    
    enum CodingKeys: String, CodingKey {
        case firstName = "first_name"
        case lastName = "last_name"
        case email
        case password
        case deviceId = "device_id"
    }
    
    public init(firstName: String, lastName: String, email: String, password: String, deviceId: String? = nil) {
        self.firstName = firstName
        self.lastName = lastName
        self.email = email
        self.password = password
        self.deviceId = deviceId
    }
}

public struct LoginRequest: Codable, Sendable {
    public let email: String
    public let password: String
    public let deviceId: String?
    
    enum CodingKeys: String, CodingKey {
        case email
        case password
        case deviceId = "device_id"
    }
    
    public init(email: String, password: String, deviceId: String? = nil) {
        self.email = email
        self.password = password
        self.deviceId = deviceId
    }
}

public struct RefreshRequest: Codable, Sendable {
    public let refreshToken: String
    public let deviceId: String?
    
    enum CodingKeys: String, CodingKey {
        case refreshToken = "refresh_token"
        case deviceId = "device_id"
    }
    
    public init(refreshToken: String, deviceId: String? = nil) {
        self.refreshToken = refreshToken
        self.deviceId = deviceId
    }
}

public struct RegisterResponse: Codable, Sendable {
    public let accessToken: String
    public let refreshToken: String
    public let user: UserProfile
    
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case user
    }
}

public struct LoginResponse: Codable, Sendable {
    public let accessToken: String
    public let refreshToken: String
    public let user: UserProfile
    
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case user
    }
}

public struct RefreshResponse: Codable, Sendable {
    public let accessToken: String
    public let user: UserProfile
    
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case user
    }
}

public struct PasswordResetCheckEmailRequest: Codable, Sendable {
    public let email: String
    
    public init(email: String) {
        self.email = email
    }
}

public struct PasswordResetCheckEmailResponse: Codable, Sendable {
    public let exists: Bool
}

public struct PasswordResetSendCodeRequest: Codable, Sendable {
    public let email: String
    
    public init(email: String) {
        self.email = email
    }
}

public struct PasswordResetSendCodeResponse: Codable, Sendable {
    public let sent: Bool
}

public struct PasswordResetVerifyRequest: Codable, Sendable {
    public let email: String
    public let code: String
    public let password: String
    
    public init(email: String, code: String, password: String) {
        self.email = email
        self.code = code
        self.password = password
    }
}

public struct PasswordResetVerifyResponse: Codable, Sendable {
    public let success: Bool
}
