import Foundation

// MARK: - Resume Profile

public struct ResumeProfile: Codable, Sendable {
    public let targetRoles: [String]
    public let experienceLevel: String?
    public let areas: [String]
    public let salaryMin: Int?
    public let currency: String?
    public let workFormat: [String]
    public let skillsTop: [String]
    public let educationLevel: String?
    public let notes: String?
    
    enum CodingKeys: String, CodingKey {
        case targetRoles = "target_roles"
        case experienceLevel = "experience_level"
        case areas
        case salaryMin = "salary_min"
        case currency
        case workFormat = "work_format"
        case skillsTop = "skills_top"
        case educationLevel = "education_level"
        case notes
    }
    
    public init(
        targetRoles: [String] = [],
        experienceLevel: String? = nil,
        areas: [String] = [],
        salaryMin: Int? = nil,
        currency: String? = nil,
        workFormat: [String] = [],
        skillsTop: [String] = [],
        educationLevel: String? = nil,
        notes: String? = nil
    ) {
        self.targetRoles = targetRoles
        self.experienceLevel = experienceLevel
        self.areas = areas
        self.salaryMin = salaryMin
        self.currency = currency
        self.workFormat = workFormat
        self.skillsTop = skillsTop
        self.educationLevel = educationLevel
        self.notes = notes
    }
}

public enum ResumeStatus: String, Codable, Sendable {
    case draft = "DRAFT"
    case confirmed = "CONFIRMED"
}

// MARK: - User Requests

public struct GetMeResponse: Codable, Sendable {
    public let user: UserProfile
}

public struct GetResumeProfileResponse: Codable, Sendable {
    public let profile: ResumeProfile?
    public let status: ResumeStatus?
    public let version: Int?
    public let sourceMaterialId: String?
    public let confirmedFields: [String]?
    public let confidence: Double?
    
    enum CodingKeys: String, CodingKey {
        case profile
        case status
        case version
        case sourceMaterialId = "source_material_id"
        case confirmedFields = "confirmed_fields"
        case confidence
    }
}

public struct UpdateResumeProfileRequest: Codable, Sendable {
    public let userId: String
    public let profile: ResumeProfile
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case profile
    }
    
    public init(userId: String, profile: ResumeProfile) {
        self.userId = userId
        self.profile = profile
    }
}

public struct UpdateResumeProfileResponse: Codable, Sendable {
    public let success: Bool
}

public struct UpdateUserProfileRequest: Codable, Sendable {
    public let firstName: String?
    public let lastName: String?
    public let email: String?
    public let notificationsEnabled: Bool?
    
    enum CodingKeys: String, CodingKey {
        case firstName = "first_name"
        case lastName = "last_name"
        case email
        case notificationsEnabled = "notifications_enabled"
    }
    
    public init(
        firstName: String? = nil,
        lastName: String? = nil,
        email: String? = nil,
        notificationsEnabled: Bool? = nil
    ) {
        self.firstName = firstName
        self.lastName = lastName
        self.email = email
        self.notificationsEnabled = notificationsEnabled
    }
}

public struct UpdateUserProfileResponse: Codable, Sendable {
    public let success: Bool
}

public struct DeleteAccountRequest: Codable, Sendable {
    public let password: String
    
    public init(password: String) {
        self.password = password
    }
}

public struct DeleteAccountResponse: Codable, Sendable {
    public let deleted: Bool
}
