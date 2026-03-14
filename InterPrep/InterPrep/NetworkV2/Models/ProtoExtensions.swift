import Foundation
import SwiftProtobuf

// MARK: - Timestamp Extensions

extension SwiftProtobuf.Google_Protobuf_Timestamp {
    init(date: Date) {
        self.init()
        self.seconds = Int64(date.timeIntervalSince1970)
        self.nanos = Int32((date.timeIntervalSince1970.truncatingRemainder(dividingBy: 1)) * 1_000_000_000)
    }
    
    var date: Date {
        Date(timeIntervalSince1970: TimeInterval(seconds) + TimeInterval(nanos) / 1_000_000_000)
    }
}

extension Date {
    func toProtoTimestamp() -> SwiftProtobuf.Google_Protobuf_Timestamp {
        SwiftProtobuf.Google_Protobuf_Timestamp(date: self)
    }
}

// MARK: - UserProfile Extensions

extension User_UserProfile {
    var displayName: String {
        if !firstName.isEmpty && !lastName.isEmpty {
            return "\(firstName) \(lastName)"
        } else if !firstName.isEmpty {
            return firstName
        } else if !lastName.isEmpty {
            return lastName
        } else {
            return username
        }
    }
}

// MARK: - Vacancy Extensions

extension Jobs_Vacancy {
    var salaryString: String? {
        guard hasSalary else { return nil }
        
        let currency = salary.currency.isEmpty ? "₽" : salary.currency
        
        if salary.hasFrom && salary.hasTo {
            return "\(salary.from) - \(salary.to) \(currency)"
        } else if salary.hasFrom {
            return "от \(salary.from) \(currency)"
        } else if salary.hasTo {
            return "до \(salary.to) \(currency)"
        }
        
        return nil
    }
    
    var employerName: String {
        hasEmployer ? employer.name : "Неизвестный работодатель"
    }
    
    var areaName: String {
        hasArea ? area.name : "Не указано"
    }
}

// MARK: - Event Extensions

extension Calendar_Event {
    var startDate: Date {
        startTime.date
    }
    
    var endDate: Date {
        endTime.date
    }
    
    var duration: TimeInterval {
        endDate.timeIntervalSince(startDate)
    }
    
    var typeString: String {
        switch eventType {
        case .interview:
            return "Собеседование"
        case .call:
            return "Звонок"
        case .meeting:
            return "Встреча"
        case .testTask:
            return "Тестовое задание"
        case .prep:
            return "Подготовка"
        case .deadline:
            return "Дедлайн"
        case .other:
            return "Другое"
        default:
            return "Событие"
        }
    }
    
    var typeEmoji: String {
        switch eventType {
        case .interview:
            return "💼"
        case .call:
            return "📞"
        case .meeting:
            return "🤝"
        case .testTask:
            return "📝"
        case .prep:
            return "📚"
        case .deadline:
            return "⏰"
        case .other:
            return "📌"
        default:
            return "📅"
        }
    }
}

// MARK: - Node Extensions

extension Materials_Node {
    var isFolder: Bool {
        type == "folder"
    }
    
    var isFile: Bool {
        type == "file"
    }
    
    var isLink: Bool {
        type == "link"
    }
    
    var fileSize: String? {
        guard hasFile else { return nil }
        let bytes = file.size
        
        if bytes < 1024 {
            return "\(bytes) B"
        } else if bytes < 1024 * 1024 {
            return String(format: "%.1f KB", Double(bytes) / 1024)
        } else if bytes < 1024 * 1024 * 1024 {
            return String(format: "%.1f MB", Double(bytes) / (1024 * 1024))
        } else {
            return String(format: "%.1f GB", Double(bytes) / (1024 * 1024 * 1024))
        }
    }
    
    var icon: String {
        if isFolder {
            return "📁"
        } else if isLink {
            return "🔗"
        } else if hasFile {
            let mimeType = file.mimeType.lowercased()
            if mimeType.contains("pdf") {
                return "📄"
            } else if mimeType.contains("image") {
                return "🖼️"
            } else if mimeType.contains("video") {
                return "🎥"
            } else if mimeType.contains("audio") {
                return "🎵"
            } else if mimeType.contains("text") {
                return "📝"
            } else {
                return "📎"
            }
        }
        return "📄"
    }
}

// MARK: - ResumeProfile Extensions

extension User_ResumeProfile {
    var experienceLevelString: String {
        guard hasExperienceLevel else { return "Не указан" }
        
        switch experienceLevel.lowercased() {
        case "junior":
            return "Junior"
        case "middle":
            return "Middle"
        case "senior":
            return "Senior"
        case "lead":
            return "Lead"
        default:
            return experienceLevel
        }
    }
    
    var salaryString: String? {
        guard hasSalaryMin else { return nil }
        let currencySymbol = hasCurrency ? currency : "₽"
        return "от \(Int(salaryMin)) \(currencySymbol)"
    }
}
