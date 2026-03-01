import Foundation

// MARK: - Vacancy

public struct Vacancy: Codable, Identifiable, Sendable {
    public let id: String
    public let name: String
    public let description: String?
    public let salary: Salary?
    public let employer: Employer?
    public let area: Area?
    public let alternateUrl: String?
    public let experience: String?
    public let isFavorite: Bool
    public let archived: Bool?
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case description
        case salary
        case employer
        case area
        case alternateUrl = "alternate_url"
        case experience
        case isFavorite = "is_favorite"
        case archived
    }
    
    public init(
        id: String,
        name: String,
        description: String? = nil,
        salary: Salary? = nil,
        employer: Employer? = nil,
        area: Area? = nil,
        alternateUrl: String? = nil,
        experience: String? = nil,
        isFavorite: Bool = false,
        archived: Bool? = nil
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.salary = salary
        self.employer = employer
        self.area = area
        self.alternateUrl = alternateUrl
        self.experience = experience
        self.isFavorite = isFavorite
        self.archived = archived
    }
}

public struct Salary: Codable, Sendable {
    public let from: Int?
    public let to: Int?
    public let currency: String?
    
    public init(from: Int? = nil, to: Int? = nil, currency: String? = nil) {
        self.from = from
        self.to = to
        self.currency = currency
    }
}

public struct Employer: Codable, Sendable {
    public let name: String?
    public let logoUrl: String?
    
    enum CodingKeys: String, CodingKey {
        case name
        case logoUrl = "logo_url"
    }
    
    public init(name: String? = nil, logoUrl: String? = nil) {
        self.name = name
        self.logoUrl = logoUrl
    }
}

public struct Area: Codable, Sendable {
    public let name: String?
    
    public init(name: String? = nil) {
        self.name = name
    }
}

// MARK: - Search Jobs

public struct SearchJobsRequest: Codable, Sendable {
    public let page: Int
    public let perPage: Int
    
    enum CodingKeys: String, CodingKey {
        case page
        case perPage = "per_page"
    }
    
    public init(page: Int = 0, perPage: Int = 10) {
        self.page = page
        self.perPage = min(perPage, 100)
    }
}

public struct SearchJobsResponse: Codable, Sendable {
    public let items: [Vacancy]
    public let found: Int
    public let page: Int
    public let pages: Int
    public let perPage: Int
    
    enum CodingKeys: String, CodingKey {
        case items
        case found
        case page
        case pages
        case perPage = "per_page"
    }
}

// MARK: - Favorites

public struct AddFavoriteRequest: Codable, Sendable {
    public let vacancyId: String
    
    enum CodingKeys: String, CodingKey {
        case vacancyId = "vacancy_id"
    }
    
    public init(vacancyId: String) {
        self.vacancyId = vacancyId
    }
}

public struct AddFavoriteResponse: Codable, Sendable {
    public let success: Bool
}

public struct RemoveFavoriteRequest: Codable, Sendable {
    public let vacancyId: String
    
    enum CodingKeys: String, CodingKey {
        case vacancyId = "vacancy_id"
    }
    
    public init(vacancyId: String) {
        self.vacancyId = vacancyId
    }
}

public struct RemoveFavoriteResponse: Codable, Sendable {
    public let success: Bool
}

public struct ListFavoritesResponse: Codable, Sendable {
    public let vacancies: [Vacancy]
}
