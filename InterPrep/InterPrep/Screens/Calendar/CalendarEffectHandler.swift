//
//  CalendarEffectHandler.swift
//  InterPrep
//
//  Calendar effect handler with notifications
//

import Foundation
import UserNotifications
import ArchitectureCore

public actor CalendarEffectHandler: EffectHandler {
    public typealias S = CalendarState
    
    private let notificationCenter = UNUserNotificationCenter.current()
    private let userDefaults = UserDefaults.standard
    private let eventsKey = "calendar_events"
    
    public init() {}
    
    public func handle(effect: CalendarState.Effect) async -> CalendarState.Feedback? {
        switch effect {
        case .loadEvents:
            return await loadEvents()
            
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
    
    private func loadEvents() async -> CalendarState.Feedback {
        do {
            if let data = userDefaults.data(forKey: eventsKey) {
                let events = try JSONDecoder().decode([CalendarState.CalendarEvent].self, from: data)
                return .eventsLoaded(events)
            } else {
                return .eventsLoaded([])
            }
        } catch {
            return .loadingFailed("Не удалось загрузить события")
        }
    }
    
    private func saveEvent(_ event: CalendarState.CalendarEvent) async -> CalendarState.Feedback {
        do {
            var events = await loadEventsSync()
            events.append(event)
            
            let data = try JSONEncoder().encode(events)
            userDefaults.set(data, forKey: eventsKey)
            
            return .eventCreated(event)
        } catch {
            return .loadingFailed("Не удалось сохранить событие")
        }
    }
    
    private func updateEvent(_ event: CalendarState.CalendarEvent) async -> CalendarState.Feedback {
        do {
            var events = await loadEventsSync()
            if let index = events.firstIndex(where: { $0.id == event.id }) {
                events[index] = event
                
                let data = try JSONEncoder().encode(events)
                userDefaults.set(data, forKey: eventsKey)
                
                return .eventUpdated(event)
            }
            return .loadingFailed("Событие не найдено")
        } catch {
            return .loadingFailed("Не удалось обновить событие")
        }
    }
    
    private func deleteEvent(_ id: String) async -> CalendarState.Feedback {
        do {
            var events = await loadEventsSync()
            events.removeAll { $0.id == id }
            
            let data = try JSONEncoder().encode(events)
            userDefaults.set(data, forKey: eventsKey)
            
            return .eventDeleted(id)
        } catch {
            return .loadingFailed("Не удалось удалить событие")
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
    
    private func loadEventsSync() async -> [CalendarState.CalendarEvent] {
        guard let data = userDefaults.data(forKey: eventsKey),
              let events = try? JSONDecoder().decode([CalendarState.CalendarEvent].self, from: data) else {
            return []
        }
        return events
    }
}
