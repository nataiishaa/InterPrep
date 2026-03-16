//
//  CalendarEffectHandler.swift
//  InterPrep
//
//  Calendar effect handler with notifications and gRPC integration
//

import Foundation
import UserNotifications
import ArchitectureCore
import NetworkService

// MARK: - Service Protocol

public protocol CalendarServiceProtocol: Actor {
    func createEvent(title: String, description: String, startTime: Date, endTime: Date, eventType: CalendarEventType, location: String?, reminderEnabled: Bool, reminderMinutes: Int32) async throws -> CalendarEvent
    func listEvents(fromTime: Date, toTime: Date) async throws -> [CalendarEvent]
    func listUpcoming(limit: Int32) async throws -> [CalendarEvent]
    func updateEvent(id: String, title: String?, description: String?, startTime: Date?, endTime: Date?, eventType: CalendarEventType?, location: String?, reminderEnabled: Bool?, reminderMinutes: Int32?, completed: Bool?) async throws -> CalendarEvent
    func deleteEvent(id: String) async throws -> Bool
}

public enum CalendarEventType: Sendable {
    case unspecified
    case interview
    case call
    case meeting
    case testTask
    case prep
    case deadline
    case other
}

public struct CalendarEvent: Sendable {
    public let id: String
    public let title: String
    public let description: String
    public let eventType: CalendarEventType
    public let startTime: Date
    public let endTime: Date
    public let timezone: String?
    public let location: String?
    public let relatedVacancyId: String?
    public let reminderEnabled: Bool
    public let reminderMinutes: Int32
    public let completed: Bool
    public let createdAt: Date
    public let updatedAt: Date
    
    public init(
        id: String,
        title: String,
        description: String,
        eventType: CalendarEventType,
        startTime: Date,
        endTime: Date,
        timezone: String? = nil,
        location: String? = nil,
        relatedVacancyId: String? = nil,
        reminderEnabled: Bool,
        reminderMinutes: Int32,
        completed: Bool = false,
        createdAt: Date,
        updatedAt: Date
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
        self.completed = completed
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - Effect Handler

public actor CalendarEffectHandler: EffectHandler {
    public typealias S = CalendarState
    
    private let notificationCenter = UNUserNotificationCenter.current()
    private let calendarService: CalendarServiceProtocol
    
    public init(calendarService: CalendarServiceProtocol) {
        self.calendarService = calendarService
    }
    
    public func handle(effect: CalendarState.Effect) async -> CalendarState.Feedback? {
        switch effect {
        case let .loadEvents(for: month):
            return await loadEvents(for: month)
            
        case let .saveEvent(event):
            return await saveEvent(event)
            
        case let .updateEvent(event):
            return await updateEvent(event)
            
        case let .deleteEvent(id):
            return await deleteEvent(id)
            
        case let .scheduleReminder(event):
            return await scheduleReminder(for: event)
            
        case let .cancelReminder(id):
            await cancelReminder(for: id)
            return nil
        }
    }
    
    // MARK: - Private Methods
    
    private func loadEvents(for month: Date) async -> CalendarState.Feedback {
        do {
            let calendar = Calendar.current
            let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: month))!
            let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth)!
            
            let serviceEvents = try await calendarService.listEvents(fromTime: startOfMonth, toTime: endOfMonth)
            let events = serviceEvents.map { mapServiceToCalendarEvent($0) }
            return .eventsLoaded(events)
        } catch {
            let message = userFacingMessage(for: error)
            return .loadingFailed(message)
        }
    }
    
    private func userFacingMessage(for error: Error) -> String {
        if let ne = error as? NetworkError, ne.isConnectionError {
            return "Проверьте подключение к интернету и попробуйте снова."
        }
        if let api = (error as? NetworkError)?.asAPIError {
            return api.userMessage
        }
        let text = error.localizedDescription.lowercased()
        if text.contains("connection was lost") || text.contains("network") || text.contains("timed out") || text.contains("offline") {
            return "Проверьте подключение к интернету и попробуйте снова."
        }
        return "Не удалось загрузить события: \(error.localizedDescription)"
    }
    
    private func saveEvent(_ event: CalendarState.CalendarEvent) async -> CalendarState.Feedback {
        do {
            let endTime = event.endDate ?? event.date.addingTimeInterval(3600)
            let serviceEvent = try await calendarService.createEvent(
                title: event.title,
                description: event.description,
                startTime: event.date,
                endTime: endTime,
                eventType: mapEventTypeToService(event.type),
                location: nil,
                reminderEnabled: event.reminderEnabled,
                reminderMinutes: Int32(event.reminderMinutesBefore)
            )
            
            let createdEvent = mapServiceToCalendarEvent(serviceEvent)
            return .eventCreated(createdEvent)
        } catch {
            return .loadingFailed(userFacingMessage(for: error).replacingOccurrences(of: "загрузить события", with: "сохранить событие"))
        }
    }
    
    private func updateEvent(_ event: CalendarState.CalendarEvent) async -> CalendarState.Feedback {
        do {
            let endTime = event.endDate ?? event.date.addingTimeInterval(3600)
            let serviceEvent = try await calendarService.updateEvent(
                id: event.id,
                title: event.title,
                description: event.description,
                startTime: event.date,
                endTime: endTime,
                eventType: mapEventTypeToService(event.type),
                location: nil,
                reminderEnabled: event.reminderEnabled,
                reminderMinutes: Int32(event.reminderMinutesBefore),
                completed: event.isCompleted
            )
            
            let updatedEvent = mapServiceToCalendarEvent(serviceEvent)
            return .eventUpdated(updatedEvent)
        } catch {
            return .loadingFailed(userFacingMessage(for: error).replacingOccurrences(of: "загрузить события", with: "обновить событие"))
        }
    }
    
    private func deleteEvent(_ id: String) async -> CalendarState.Feedback {
        do {
            let success = try await calendarService.deleteEvent(id: id)
            if success {
                return .eventDeleted(id)
            } else {
                return .loadingFailed("Не удалось удалить событие")
            }
        } catch {
            return .loadingFailed(userFacingMessage(for: error))
        }
    }
    
    // MARK: - Mapping Helpers
    
    private func mapServiceToCalendarEvent(_ serviceEvent: CalendarEvent) -> CalendarState.CalendarEvent {
        CalendarState.CalendarEvent(
            id: serviceEvent.id,
            title: serviceEvent.title,
            description: serviceEvent.description,
            date: serviceEvent.startTime,
            endDate: serviceEvent.endTime,
            type: mapServiceToEventType(serviceEvent.eventType),
            reminderEnabled: serviceEvent.reminderEnabled,
            reminderMinutesBefore: Int(serviceEvent.reminderMinutes),
            isCompleted: serviceEvent.completed
        )
    }
    
    private func mapServiceToEventType(_ serviceType: CalendarEventType) -> CalendarState.EventType {
        switch serviceType {
        case .interview:
            return .interview
        case .call:
            return .call
        case .meeting:
            return .meeting
        case .testTask:
            return .test
        case .deadline:
            return .deadline
        case .other, .unspecified, .prep:
            return .other
        }
    }
    
    private func mapEventTypeToService(_ type: CalendarState.EventType) -> CalendarEventType {
        switch type {
        case .interview:
            return .interview
        case .call:
            return .call
        case .meeting:
            return .meeting
        case .test:
            return .testTask
        case .deadline:
            return .deadline
        case .other:
            return .other
        }
    }
    
    private func scheduleReminder(for event: CalendarState.CalendarEvent) async -> CalendarState.Feedback {
        // Request notification permission
        let granted = await requestNotificationPermission()
        guard granted else {
            return .loadingFailed("Разрешите уведомления в настройках")
        }
        
        // Create notification content
        let content = UNMutableNotificationContent()
        content.title = "Напоминание"
        content.body = event.title
        content.sound = .default
        content.categoryIdentifier = "EVENT_REMINDER"
        
        if !event.description.isEmpty {
            content.subtitle = event.description
        }
        
        // Calculate trigger date
        let triggerDate = event.reminderDate
        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: triggerDate
        )
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        
        // Create request
        let request = UNNotificationRequest(
            identifier: event.id,
            content: content,
            trigger: trigger
        )
        
        do {
            try await notificationCenter.add(request)
            return .reminderScheduled(event)
        } catch {
            return .loadingFailed("Не удалось создать напоминание")
        }
    }
    
    private func cancelReminder(for id: String) async {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [id])
    }
    
    private func requestNotificationPermission() async -> Bool {
        do {
            return try await notificationCenter.requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }
}

// MARK: - Mock Service for Preview

public final actor MockCalendarService: CalendarServiceProtocol {
    public init() {}
    
    public func createEvent(title: String, description: String, startTime: Date, endTime: Date, eventType: CalendarEventType, location: String?, reminderEnabled: Bool, reminderMinutes: Int32) async throws -> CalendarEvent {
        CalendarEvent(
            id: UUID().uuidString,
            title: title,
            description: description,
            eventType: eventType,
            startTime: startTime,
            endTime: endTime,
            location: location,
            reminderEnabled: reminderEnabled,
            reminderMinutes: reminderMinutes,
            completed: false,
            createdAt: Date(),
            updatedAt: Date()
        )
    }
    
    public func listEvents(fromTime: Date, toTime: Date) async throws -> [CalendarEvent] {
        []
    }
    
    public func listUpcoming(limit: Int32) async throws -> [CalendarEvent] {
        []
    }
    
    public func updateEvent(id: String, title: String?, description: String?, startTime: Date?, endTime: Date?, eventType: CalendarEventType?, location: String?, reminderEnabled: Bool?, reminderMinutes: Int32?, completed: Bool?) async throws -> CalendarEvent {
        CalendarEvent(
            id: id,
            title: title ?? "Updated Event",
            description: description ?? "",
            eventType: eventType ?? .other,
            startTime: startTime ?? Date(),
            endTime: endTime ?? Date(),
            location: location,
            reminderEnabled: reminderEnabled ?? false,
            reminderMinutes: reminderMinutes ?? 30,
            completed: completed ?? false,
            createdAt: Date(),
            updatedAt: Date()
        )
    }
    
    public func deleteEvent(id: String) async throws -> Bool {
        true
    }
}
