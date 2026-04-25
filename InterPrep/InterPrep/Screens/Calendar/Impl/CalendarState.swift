//
//  CalendarState.swift
//  InterPrep
//
//  Calendar feature state
//

import ArchitectureCore
import Foundation

public struct CalendarState {
    public var selectedDate: Date = Date()
    public var currentMonth: Date = Date()
    public var events: [CalendarEvent] = []
    public var isCreatingEvent: Bool = false
    public var isLoading: Bool = false
    public var errorMessage: String?
    public var isOfflineMode: Bool = false
    
    public var editingEventId: String?
    public var newEventTitle: String = ""
    public var newEventDescription: String = ""
    public var newEventDate: Date = Date()
    public var newEventTime: Date = Date()
    public var newEventEndDate: Date = Date().addingTimeInterval(3600)
    public var newEventType: EventType = .interview
    public var newEventReminderEnabled: Bool = true
    public var newEventReminderMinutes: Int = 30
    
    public init() {}
}

extension CalendarState {
    public struct CalendarEvent: Identifiable, Equatable, Codable, Sendable {
        public let id: String
        public let title: String
        public let description: String
        public let date: Date
        public let endDate: Date?
        public let type: EventType
        public let reminderEnabled: Bool
        public let reminderMinutesBefore: Int
        public var isCompleted: Bool
        
        public init(
            id: String = UUID().uuidString,
            title: String,
            description: String,
            date: Date,
            endDate: Date? = nil,
            type: EventType,
            reminderEnabled: Bool = true,
            reminderMinutesBefore: Int = 30,
            isCompleted: Bool = false
        ) {
            self.id = id
            self.title = title
            self.description = description
            self.date = date
            self.endDate = endDate
            self.type = type
            self.reminderEnabled = reminderEnabled
            self.reminderMinutesBefore = reminderMinutesBefore
            self.isCompleted = isCompleted
        }
        
        public var reminderDate: Date {
            date.addingTimeInterval(-Double(reminderMinutesBefore * 60))
        }
    }
    
    public enum EventType: String, CaseIterable, Codable, Sendable {
        case interview = "Собеседование"
        case test = "Тестовое задание"
        case call = "Звонок"
        case meeting = "Встреча"
        case deadline = "Дедлайн"
        case other = "Другое"
        
        public var icon: String {
            switch self {
            case .interview: return "person.2.fill"
            case .test: return "doc.text.fill"
            case .call: return "phone.fill"
            case .meeting: return "calendar"
            case .deadline: return "clock.fill"
            case .other: return "star.fill"
            }
        }
        
        public var color: String {
            switch self {
            case .interview: return "brandPrimary"
            case .test: return "blue"
            case .call: return "green"
            case .meeting: return "orange"
            case .deadline: return "red"
            case .other: return "purple"
            }
        }
    }
}

extension CalendarState: FeatureState {
    public enum Input: Sendable {
        case onAppear
        case dateSelected(Date)
        case monthChanged(Date)
        case createEventTapped
        case cancelEventCreation
        
        case eventTitleChanged(String)
        case eventDescriptionChanged(String)
        case eventDateChanged(Date)
        case eventTimeChanged(Date)
        case eventEndDateChanged(Date)
        case eventTypeChanged(EventType)
        case eventReminderToggled(Bool)
        case eventReminderMinutesChanged(Int)
        case saveEventTapped
        
        case deleteEvent(String)
        case editEvent(CalendarEvent)
        case syncCompleted([CalendarEvent])
        case retryTapped
    }
    
    public enum Feedback: Sendable {
        case eventsLoaded([CalendarEvent])
        case eventsLoadedFromCache([CalendarEvent])
        case eventCreated(CalendarEvent)
        case eventUpdated(CalendarEvent)
        case eventDeleted(String)
        case loadingFailed(String)
        case reminderScheduled(CalendarEvent)
    }
    
    public enum Effect: Sendable {
        case loadEvents(for: Date)
        case saveEvent(CalendarEvent)
        case updateEvent(CalendarEvent)
        case deleteEvent(String)
        case scheduleReminder(CalendarEvent)
        case cancelReminder(String)
    }
    
    @MainActor
    // swiftlint:disable:next function_body_length
    public static func reduce(
        state: inout Self,
        with message: Message<Input, Feedback>
    ) -> Effect? {
        switch message {
        case .input(.onAppear):
            state.isLoading = true
            return .loadEvents(for: state.currentMonth)
            
        case let .input(.dateSelected(date)):
            state.selectedDate = date
            
        case let .input(.monthChanged(date)):
            state.currentMonth = date
            state.isLoading = true
            return .loadEvents(for: date)
            
        case .input(.createEventTapped):
            state.editingEventId = nil
            state.isCreatingEvent = true
            state.newEventDate = state.selectedDate
            state.newEventTime = Date()
            let cal = Calendar.current
            let startComps = cal.dateComponents([.year, .month, .day], from: state.newEventDate)
            let timeComps = cal.dateComponents([.hour, .minute], from: state.newEventTime)
            var combined = DateComponents()
            combined.year = startComps.year
            combined.month = startComps.month
            combined.day = startComps.day
            combined.hour = timeComps.hour
            combined.minute = timeComps.minute
            let startDate = cal.date(from: combined) ?? Date()
            state.newEventEndDate = startDate.addingTimeInterval(3600)
            state.newEventTitle = ""
            state.newEventDescription = ""
            state.newEventType = .interview
            state.newEventReminderEnabled = true
            state.newEventReminderMinutes = 30
            
        case .input(.cancelEventCreation):
            state.editingEventId = nil
            state.isCreatingEvent = false
            state.errorMessage = nil
            
        case let .input(.eventTitleChanged(title)):
            state.newEventTitle = title
            state.errorMessage = nil
            
        case let .input(.eventDescriptionChanged(description)):
            state.newEventDescription = description
            
        case let .input(.eventDateChanged(date)):
            state.newEventDate = date
            
        case let .input(.eventTimeChanged(time)):
            state.newEventTime = time
            
        case let .input(.eventEndDateChanged(date)):
            state.newEventEndDate = date
            
        case let .input(.eventTypeChanged(type)):
            state.newEventType = type
            
        case let .input(.eventReminderToggled(enabled)):
            state.newEventReminderEnabled = enabled
            
        case let .input(.eventReminderMinutesChanged(minutes)):
            state.newEventReminderMinutes = minutes
            
        case .input(.saveEventTapped):
            guard !state.newEventTitle.isEmpty else {
                state.errorMessage = "Введите название события"
                return nil
            }
            
            let calendar = Calendar.current
            let dateComponents = calendar.dateComponents([.year, .month, .day], from: state.newEventDate)
            let timeComponents = calendar.dateComponents([.hour, .minute], from: state.newEventTime)
            
            var combinedComponents = DateComponents()
            combinedComponents.year = dateComponents.year
            combinedComponents.month = dateComponents.month
            combinedComponents.day = dateComponents.day
            combinedComponents.hour = timeComponents.hour
            combinedComponents.minute = timeComponents.minute
            
            guard let eventDate = calendar.date(from: combinedComponents) else {
                state.errorMessage = "Неверная дата"
                return nil
            }
            
            let eventId = state.editingEventId ?? UUID().uuidString
            let isCompleted: Bool
            if let editingId = state.editingEventId,
               let existing = state.events.first(where: { $0.id == editingId }) {
                isCompleted = existing.isCompleted
            } else {
                isCompleted = false
            }
            let event = CalendarEvent(
                id: eventId,
                title: state.newEventTitle,
                description: state.newEventDescription,
                date: eventDate,
                endDate: state.newEventEndDate,
                type: state.newEventType,
                reminderEnabled: state.newEventReminderEnabled,
                reminderMinutesBefore: state.newEventReminderMinutes,
                isCompleted: isCompleted
            )
            
            state.isLoading = true
            if state.editingEventId != nil {
                state.editingEventId = nil
                return .updateEvent(event)
            }
            return .saveEvent(event)
            
        case let .input(.deleteEvent(id)):
            return .deleteEvent(id)
            
        case let .input(.editEvent(event)):
            state.editingEventId = event.id
            state.isCreatingEvent = true
            state.newEventTitle = event.title
            state.newEventDescription = event.description
            state.newEventDate = event.date
            state.newEventTime = event.date
            state.newEventEndDate = event.endDate ?? event.date.addingTimeInterval(3600)
            state.newEventType = event.type
            state.newEventReminderEnabled = event.reminderEnabled
            state.newEventReminderMinutes = event.reminderMinutesBefore
            
        case let .input(.syncCompleted(events)):
            state.events = events
            
        case .input(.retryTapped):
            state.errorMessage = nil
            state.isLoading = true
            return .loadEvents(for: state.currentMonth)
            
        case let .feedback(.eventsLoaded(events)):
            state.isLoading = false
            state.events = events
            state.isOfflineMode = false
            state.errorMessage = nil
            
        case let .feedback(.eventsLoadedFromCache(events)):
            state.isLoading = false
            state.events = events
            state.isOfflineMode = true
            state.errorMessage = nil
            
        case let .feedback(.eventCreated(event)):
            state.editingEventId = nil
            state.isLoading = false
            state.isCreatingEvent = false
            state.events.append(event)
            if event.reminderEnabled {
                return .scheduleReminder(event)
            }
            
        case let .feedback(.eventUpdated(event)):
            state.editingEventId = nil
            if let index = state.events.firstIndex(where: { $0.id == event.id }) {
                state.events[index] = event
            }
            
        case let .feedback(.eventDeleted(id)):
            state.events.removeAll { $0.id == id }
            return .cancelReminder(id)
            
        case let .feedback(.loadingFailed(error)):
            state.isLoading = false
            state.errorMessage = error
            
        case let .feedback(.reminderScheduled(event)):
            break
        }
        
        return nil
    }
}

extension Date {
    var startOfMonth: Date {
        Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: self))!
    }
    
    var endOfMonth: Date {
        Calendar.current.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth)!
    }
    
    func isSameDay(as date: Date) -> Bool {
        Calendar.current.isDate(self, inSameDayAs: date)
    }
    
    func isSameMonth(as date: Date) -> Bool {
        Calendar.current.isDate(self, equalTo: date, toGranularity: .month)
    }
}
