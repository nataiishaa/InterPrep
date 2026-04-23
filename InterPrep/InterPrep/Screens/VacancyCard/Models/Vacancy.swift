//
//  Vacancy.swift
//  VacancyCardModule
//
//  Модель данных для вакансии
//

import Foundation

public struct Vacancy: Identifiable, Codable, Equatable {
    public let id: String
    public let title: String
    public let company: String
    public let location: String
    public let salary: SalaryRange?
    public let employmentType: EmploymentType
    public let experienceLevel: ExperienceLevel
    public let description: String
    public let requirements: [String]
    public let benefits: [String]
    public let tags: [String]
    public let postedDate: Date
    public let applicationDeadline: Date?
    public let isRemote: Bool
    public let companyLogo: String?
    
    public init(
        id: String,
        title: String,
        company: String,
        location: String,
        salary: SalaryRange? = nil,
        employmentType: EmploymentType,
        experienceLevel: ExperienceLevel,
        description: String,
        requirements: [String] = [],
        benefits: [String] = [],
        tags: [String] = [],
        postedDate: Date,
        applicationDeadline: Date? = nil,
        isRemote: Bool = false,
        companyLogo: String? = nil
    ) {
        self.id = id
        self.title = title
        self.company = company
        self.location = location
        self.salary = salary
        self.employmentType = employmentType
        self.experienceLevel = experienceLevel
        self.description = description
        self.requirements = requirements
        self.benefits = benefits
        self.tags = tags
        self.postedDate = postedDate
        self.applicationDeadline = applicationDeadline
        self.isRemote = isRemote
        self.companyLogo = companyLogo
    }
}

public struct SalaryRange: Codable, Equatable {
    public let min: Int
    public let max: Int
    public let currency: String
    public let period: SalaryPeriod
    
    public init(min: Int, max: Int, currency: String = "₽", period: SalaryPeriod = .monthly) {
        self.min = min
        self.max = max
        self.currency = currency
        self.period = period
    }
    
    public var formatted: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = " "
        
        let minFormatted = formatter.string(from: NSNumber(value: min)) ?? "\(min)"
        let maxFormatted = formatter.string(from: NSNumber(value: max)) ?? "\(max)"
        
        return "\(minFormatted)–\(maxFormatted) \(currency)"
    }
}

public enum EmploymentType: String, Codable, CaseIterable {
    case fullTime = "full_time"
    case partTime = "part_time"
    case contract = "contract"
    case internship = "internship"
    case freelance = "freelance"
    
    public var displayName: String {
        switch self {
        case .fullTime: return "Полная занятость"
        case .partTime: return "Частичная занятость"
        case .contract: return "Контракт"
        case .internship: return "Стажировка"
        case .freelance: return "Фриланс"
        }
    }
}

public enum ExperienceLevel: String, Codable, CaseIterable {
    case intern
    case junior
    case middle
    case senior
    case lead
    
    public var displayName: String {
        switch self {
        case .intern: return "Стажёр"
        case .junior: return "Junior"
        case .middle: return "Middle"
        case .senior: return "Senior"
        case .lead: return "Lead"
        }
    }
}

public enum SalaryPeriod: String, Codable {
    case hourly
    case monthly
    case yearly
    
    public var displayName: String {
        switch self {
        case .hourly: return "в час"
        case .monthly: return "в месяц"
        case .yearly: return "в год"
        }
    }
}

#if DEBUG
extension Vacancy {
    public static let mock1 = Vacancy(
        id: "1",
        title: "iOS Developer",
        company: "Яндекс",
        location: "Москва",
        salary: SalaryRange(min: 200_000, max: 350_000),
        employmentType: .fullTime,
        experienceLevel: .middle,
        description: "Разработка мобильных приложений на iOS",
        requirements: ["Swift", "SwiftUI", "UIKit", "3+ года опыта"],
        benefits: ["ДМС", "Офис в центре", "Гибкий график"],
        tags: ["iOS", "Swift", "Mobile"],
        postedDate: Date().addingTimeInterval(-86400 * 2),
        applicationDeadline: Date().addingTimeInterval(86400 * 30),
        isRemote: false,
        companyLogo: nil
    )
    
    public static let mock2 = Vacancy(
        id: "2",
        title: "Senior Swift Developer",
        company: "Тинькoff",
        location: "Удалённо",
        salary: SalaryRange(min: 300_000, max: 450_000),
        employmentType: .fullTime,
        experienceLevel: .senior,
        description: "Разработка банковских приложений",
        requirements: ["Swift", "Архитектура", "5+ лет опыта"],
        benefits: ["Удалённая работа", "ДМС", "Обучение"],
        tags: ["iOS", "Swift", "FinTech"],
        postedDate: Date().addingTimeInterval(-86400 * 5),
        isRemote: true,
        companyLogo: nil
    )
    
    public static let mock3 = Vacancy(
        id: "3",
        title: "Junior iOS Developer",
        company: "VK",
        location: "Санкт-Петербург",
        salary: SalaryRange(min: 120_000, max: 180_000),
        employmentType: .fullTime,
        experienceLevel: .junior,
        description: "Разработка социальных приложений",
        requirements: ["Swift", "UIKit", "1+ год опыта"],
        benefits: ["Офис", "ДМС", "Корпоративное обучение"],
        tags: ["iOS", "Swift", "Social"],
        postedDate: Date().addingTimeInterval(-86400),
        isRemote: false,
        companyLogo: nil
    )
    
    public static let mocks: [Vacancy] = [mock1, mock2, mock3]
}
#endif
