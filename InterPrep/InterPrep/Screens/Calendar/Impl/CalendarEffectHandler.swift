import AnalyticsService
import ArchitectureCore
import CacheService
import Foundation
import NetworkMonitorService
import NetworkService
import NotificationService
import UserNotifications

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

public actor CalendarEffectHandler: EffectHandler {
    public typealias StateType = CalendarState

    private let calendarService: CalendarServicing
    private let cacheManager = CacheManager.shared
    private var caldavSyncManager: CalDAVSyncManager?
    private var isCalDAVSetup = false

    public init(calendarService: CalendarServicing) {
        self.calendarService = calendarService
    }

    private func ensureCalDAVSetup() async {
        guard !isCalDAVSetup else { return }
        isCalDAVSetup = true

        let settings = CalDAVSettingsManager.shared.loadSettings()
        guard settings.isEnabled else { return }

        let manager = CalDAVSyncManager()
        do {
            try await manager.setup()
            self.caldavSyncManager = manager
        } catch {
            print("CalDAV setup failed: \(error.localizedDescription)")
        }
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

    private func loadEvents(for month: Date) async -> CalendarState.Feedback {
        let calendar = Calendar.current
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: month))!
        let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth)!

        let cacheKey = CacheKey.calendarEvents(month: month)

        let isConnected = await MainActor.run { NetworkMonitor.shared.isConnected }
        if !isConnected {
            if let cachedEvents = try? await cacheManager.load(forKey: cacheKey, as: [CalendarState.CalendarEvent].self) {
                return .eventsLoadedFromCache(cachedEvents)
            }
            return .loadingFailed("Нет интернета. Проверьте подключение и попробуйте снова")
        }

        do {
            let serviceEvents = try await calendarService.listEvents(fromTime: startOfMonth, toTime: endOfMonth)
            let events = serviceEvents.map { mapServiceToCalendarEvent($0) }
            try? await cacheManager.save(events, forKey: cacheKey)
            return .eventsLoaded(events)
        } catch {
            if let cachedEvents = try? await cacheManager.load(forKey: cacheKey, as: [CalendarState.CalendarEvent].self) {
                return .eventsLoadedFromCache(cachedEvents)
            }
            let message = await userFacingMessage(for: error)
            return .loadingFailed(message)
        }
    }

    @MainActor
    private func connectionMessage() -> String {
        NetworkMonitor.shared.isConnected
            ? "Не удалось подключиться к серверу. Возможно, включён VPN — попробуйте отключить его"
            : "Нет интернета. Проверьте подключение и попробуйте снова"
    }

    private func userFacingMessage(for error: Error) async -> String {
        if let ne = error as? NetworkError, ne.isConnectionError {
            return await connectionMessage()
        }
        if let api = (error as? NetworkError)?.asAPIError {
            return api.userMessage
        }
        let text = String(describing: error).lowercased()
        if text.contains("connection was lost") || text.contains("network") || text.contains("timed out") || text.contains("offline") {
            return await connectionMessage()
        }
        return "Не удалось загрузить события"
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
            await trackEvent(.calendarEventCreated(eventId: createdEvent.id))

            let calendar = Calendar.current
            let month = calendar.date(from: calendar.dateComponents([.year, .month], from: event.date))!
            let cacheKey = CacheKey.calendarEvents(month: month)
            if var cachedEvents = try? await cacheManager.load(forKey: cacheKey, as: [CalendarState.CalendarEvent].self) {
                cachedEvents.append(createdEvent)
                try? await cacheManager.save(cachedEvents, forKey: cacheKey)
            }

            await syncToCalDAV(event: createdEvent)

            return .eventCreated(createdEvent)
        } catch {
            if (error as? NetworkError)?.isConnectionError == true {
                await MainActor.run {
                    OfflineSyncManager.shared.addOperation(.createCalendarEvent(
                        title: event.title,
                        description: event.description,
                        startTime: event.date,
                        endTime: event.endDate ?? event.date.addingTimeInterval(3600),
                        eventType: event.type.rawValue,
                        reminderEnabled: event.reminderEnabled,
                        reminderMinutes: Int32(event.reminderMinutesBefore)
                    ))
                }
                return .eventCreated(event)
            }
            return .loadingFailed(await userFacingMessage(for: error).replacingOccurrences(of: "загрузить события", with: "сохранить событие"))
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

            let calendar = Calendar.current
            let month = calendar.date(from: calendar.dateComponents([.year, .month], from: event.date))!
            let cacheKey = CacheKey.calendarEvents(month: month)
            if var cachedEvents = try? await cacheManager.load(forKey: cacheKey, as: [CalendarState.CalendarEvent].self) {
                if let index = cachedEvents.firstIndex(where: { $0.id == updatedEvent.id }) {
                    cachedEvents[index] = updatedEvent
                    try? await cacheManager.save(cachedEvents, forKey: cacheKey)
                }
            }

            await syncToCalDAV(event: updatedEvent)

            return .eventUpdated(updatedEvent)
        } catch {
            if (error as? NetworkError)?.isConnectionError == true {
                await MainActor.run {
                    OfflineSyncManager.shared.addOperation(.updateCalendarEvent(
                        id: event.id,
                        title: event.title,
                        description: event.description,
                        startTime: event.date,
                        endTime: event.endDate ?? event.date.addingTimeInterval(3600),
                        eventType: event.type.rawValue,
                        reminderEnabled: event.reminderEnabled,
                        reminderMinutes: Int32(event.reminderMinutesBefore),
                        completed: event.isCompleted
                    ))
                }
                return .eventUpdated(event)
            }
            return .loadingFailed(await userFacingMessage(for: error).replacingOccurrences(of: "загрузить события", with: "обновить событие"))
        }
    }

    private func deleteEvent(_ id: String) async -> CalendarState.Feedback {
        do {
            let success = try await calendarService.deleteEvent(id: id)
            if success {
                await trackEvent(.calendarEventDeleted(eventId: id))

                if let allEvents = try? await cacheManager.load(forKey: CacheKey.allCalendarEvents, as: [CalendarState.CalendarEvent].self) {
                    let filtered = allEvents.filter { $0.id != id }
                    try? await cacheManager.save(filtered, forKey: CacheKey.allCalendarEvents)
                }

                await deleteFromCalDAV(eventId: id)

                return .eventDeleted(id)
            } else {
                return .loadingFailed("Не удалось удалить событие")
            }
        } catch {
            if (error as? NetworkError)?.isConnectionError == true {
                await MainActor.run {
                    OfflineSyncManager.shared.addOperation(.deleteCalendarEvent(id: id))
                }
                return .eventDeleted(id)
            }
            return .loadingFailed(await userFacingMessage(for: error))
        }
    }

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

    @MainActor
    private func scheduleReminder(for event: CalendarState.CalendarEvent) async -> CalendarState.Feedback {
        let manager = NotificationManager.shared

        guard manager.isEnabled else {
            return .loadingFailed("Уведомления отключены в настройках приложения")
        }

        if !manager.isAuthorized {
            let granted = await manager.requestAuthorization()
            guard granted else {
                return .loadingFailed("Разрешите уведомления в настройках")
            }
        }

        let subtitle = event.description.isEmpty ? nil : event.description

        do {
            try await manager.scheduleLocalNotification(
                id: event.id,
                title: "Напоминание",
                body: event.title,
                subtitle: subtitle,
                triggerDate: event.reminderDate,
                categoryIdentifier: "EVENT_REMINDER",
                userInfo: ["event_id": event.id, "type": "calendar_event"]
            )
            return .reminderScheduled(event)
        } catch let error as NotificationError {
            return .loadingFailed(error.localizedDescription)
        } catch {
            return .loadingFailed("Не удалось создать напоминание")
        }
    }

    @MainActor
    private func cancelReminder(for id: String) async {
        NotificationManager.shared.cancelLocalNotification(id: id)
    }

    @MainActor
    private func trackEvent(_ event: AnalyticsEvent) {
        AnalyticsManager.shared.track(event)
    }

    private func syncToCalDAV(event: CalendarState.CalendarEvent) async {
        await ensureCalDAVSetup()
        guard let manager = caldavSyncManager else { return }

        do {
            try await manager.pushEvent(event)
        } catch {
            print("CalDAV sync failed: \(error.localizedDescription)")
        }
    }

    private func deleteFromCalDAV(eventId: String) async {
        await ensureCalDAVSetup()
        guard let manager = caldavSyncManager else { return }

        let dummyEvent = CalendarState.CalendarEvent(
            id: eventId,
            title: "",
            description: "",
            date: Date(),
            endDate: nil,
            type: .other,
            reminderEnabled: false,
            reminderMinutesBefore: 0,
            isCompleted: false
        )

        do {
            try await manager.deleteEvent(dummyEvent)
        } catch {
            print("CalDAV delete failed: \(error.localizedDescription)")
        }
    }
}

#if DEBUG

public final actor MockCalendarService: CalendarServicing {
    public init() {}

    public func createEvent(
        title: String,
        description: String,
        startTime: Date,
        endTime: Date,
        eventType: CalendarEventType
    ) async throws -> CalendarEvent {
        try await createEvent(
            title: title,
            description: description,
            startTime: startTime,
            endTime: endTime,
            eventType: eventType,
            location: nil,
            reminderEnabled: false,
            reminderMinutes: 15
        )
    }

    // swiftlint:disable:next function_parameter_count
    public func createEvent(
        title: String,
        description: String,
        startTime: Date,
        endTime: Date,
        eventType: CalendarEventType,
        location: String?,
        reminderEnabled: Bool,
        reminderMinutes: Int32
    ) async throws -> CalendarEvent {
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

    public func updateEvent(
        id: String,
        title: String?,
        description: String?,
        startTime: Date?,
        endTime: Date?
    ) async throws -> CalendarEvent {
        try await updateEvent(
            id: id,
            title: title,
            description: description,
            startTime: startTime,
            endTime: endTime,
            eventType: nil,
            location: nil,
            reminderEnabled: nil,
            reminderMinutes: nil,
            completed: nil
        )
    }

    // swiftlint:disable:next function_parameter_count
    public func updateEvent(
        id: String,
        title: String?,
        description: String?,
        startTime: Date?,
        endTime: Date?,
        eventType: CalendarEventType?,
        location: String?,
        reminderEnabled: Bool?,
        reminderMinutes: Int32?,
        completed: Bool?
    ) async throws -> CalendarEvent {
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

#endif
