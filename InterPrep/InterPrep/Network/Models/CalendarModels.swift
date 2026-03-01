import Foundation

// MARK: - Event Type

public enum EventType: String, Codable, Sendable, CaseIterable {
    case interview = "INTERVIEW"
    case call = "CALL"
    case meeting = "MEETING"
    case testTask = "TEST_TASK"
    case prep = "PREP"
    case deadline = "DEADLINE"
    case other = "OTHER"
}

// MARK: - Event

public struct Event: Codable, Identifiable, Sendable {
    public let id: String
    public let title: String
    public let description: String?
    public let eventType: EventType
    public let startTime: Date
    public let endTime: Date?
    public let timezone: String?
    public let location: String?
    public let relatedVacancyId: String?
    public let reminderEnabled: Bool
    public let reminderMinutes: Int?
    public let createdAt: Date?
    public let updatedAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case description
        case eventType = "event_type"
        case startTime = "start_time"
        case endTime = "end_time"
        case timezone
        case location
        case relatedVacancyId = "related_vacancy_id"
        case reminderEnabled = "reminder_enabled"
        case reminderMinutes = "reminder_minutes"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    public init(
        id: String = UUID().uuidString,
        title: String,
        description: String? = nil,
        eventType: EventType,
        startTime: Date,
        endTime: Date? = nil,
        timezone: String? = nil,
        location: String? = nil,
        relatedVacancyId: String? = nil,
        reminderEnabled: Bool = false,
        reminderMinutes: Int? = nil,
        createdAt: Date? = nil,
        updatedAt: Date? = nil
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.eventType = eventType
        self.startTime = startTime
        self.endTime = endTime
        self.timezone = timezone
        self.location = location
        self.relatedVacancyId = relatedVacancyId
        self.reminderEnabled = reminderEnabled
        self.reminderMinutes = reminderMinutes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - Event Patch

public struct EventPatch: Codable, Sendable {
    public let title: String?
    public let description: String?
    public let eventType: EventType?
    public let startTime: Date?
    public let endTime: Date?
    public let timezone: String?
    public let location: String?
    public let relatedVacancyId: String?
    public let reminderEnabled: Bool?
    public let reminderMinutes: Int?
    
    enum CodingKeys: String, CodingKey {
        case title
        case description
        case eventType = "event_type"
        case startTime = "start_time"
        case endTime = "end_time"
        case timezone
        case location
        case relatedVacancyId = "related_vacancy_id"
        case reminderEnabled = "reminder_enabled"
        case reminderMinutes = "reminder_minutes"
    }
    
    public init(
        title: String? = nil,
        description: String? = nil,
        eventType: EventType? = nil,
        startTime: Date? = nil,
        endTime: Date? = nil,
        timezone: String? = nil,
        location: String? = nil,
        relatedVacancyId: String? = nil,
        reminderEnabled: Bool? = nil,
        reminderMinutes: Int? = nil
    ) {
        self.title = title
        self.description = description
        self.eventType = eventType
        self.startTime = startTime
        self.endTime = endTime
        self.timezone = timezone
        self.location = location
        self.relatedVacancyId = relatedVacancyId
        self.reminderEnabled = reminderEnabled
        self.reminderMinutes = reminderMinutes
    }
}

// MARK: - Sort Order

public enum EventSortOrder: String, Codable, Sendable {
    case startAsc = "SORT_START_ASC"
    case startDesc = "SORT_START_DESC"
}

// MARK: - Calendar Requests

public struct CreateEventRequest: Codable, Sendable {
    public let event: Event
    
    public init(event: Event) {
        self.event = event
    }
}

public struct CreateEventResponse: Codable, Sendable {
    public let event: Event
}

public struct GetEventRequest: Codable, Sendable {
    public let id: String
    
    public init(id: String) {
        self.id = id
    }
}

public struct GetEventResponse: Codable, Sendable {
    public let event: Event
}

public struct UpdateEventRequest: Codable, Sendable {
    public let id: String
    public let patch: EventPatch
    
    public init(id: String, patch: EventPatch) {
        self.id = id
        self.patch = patch
    }
}

public struct UpdateEventResponse: Codable, Sendable {
    public let event: Event
}

public struct DeleteEventRequest: Codable, Sendable {
    public let id: String
    
    public init(id: String) {
        self.id = id
    }
}

public struct DeleteEventResponse: Codable, Sendable {
    public let success: Bool
}

public struct ListEventsRequest: Codable, Sendable {
    public let fromTime: Date
    public let toTime: Date
    public let pageSize: Int?
    public let pageToken: String?
    public let sort: EventSortOrder?
    
    enum CodingKeys: String, CodingKey {
        case fromTime = "from_time"
        case toTime = "to_time"
        case pageSize = "page_size"
        case pageToken = "page_token"
        case sort
    }
    
    public init(
        fromTime: Date,
        toTime: Date,
        pageSize: Int? = nil,
        pageToken: String? = nil,
        sort: EventSortOrder? = nil
    ) {
        self.fromTime = fromTime
        self.toTime = toTime
        self.pageSize = pageSize
        self.pageToken = pageToken
        self.sort = sort
    }
}

public struct ListEventsResponse: Codable, Sendable {
    public let events: [Event]
    public let nextPageToken: String?
    
    enum CodingKeys: String, CodingKey {
        case events
        case nextPageToken = "next_page_token"
    }
}

public struct ListUpcomingRequest: Codable, Sendable {
    public let limit: Int
    public let fromTime: Date?
    
    enum CodingKeys: String, CodingKey {
        case limit
        case fromTime = "from_time"
    }
    
    public init(limit: Int, fromTime: Date? = nil) {
        self.limit = limit
        self.fromTime = fromTime
    }
}

public struct ListUpcomingResponse: Codable, Sendable {
    public let events: [Event]
}
