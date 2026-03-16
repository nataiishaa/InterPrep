//
//  CalDAVSyncManager.swift
//  InterPrep
//
//  CalDAV synchronization manager
//

import Foundation

final class CalDAVSyncManager {
    
    private let settingsManager = CalDAVSettingsManager.shared
    private var client: CalDAVClient?
    private var selectedCalendar: CalDAVCalendar?
    
    func setup() async throws {
        let settings = settingsManager.loadSettings()
        guard let client = settingsManager.createClient(from: settings) else {
            throw CalDAVError.requestFailed
        }
        
        self.client = client
        
        if settings.selectedCalendarURL == nil {
            try await discoverAndSelectCalendar()
        } else if let calendarURL = settings.selectedCalendarURL,
                  let url = URL(string: calendarURL) {
            self.selectedCalendar = CalDAVCalendar(
                url: url,
                displayName: "InterPrep Calendar",
                description: nil
            )
        }
    }
    
    private func discoverAndSelectCalendar() async throws {
        guard let client = client else { return }
        
        _ = try await client.discoverPrincipal()
        _ = try await client.discoverCalendarHome()
        let calendars = try await client.listCalendars()
        
        if let firstCalendar = calendars.first {
            self.selectedCalendar = firstCalendar
            
            var settings = settingsManager.loadSettings()
            settings.selectedCalendarURL = firstCalendar.url.absoluteString
            settingsManager.saveSettings(settings)
        } else {
            let newCalendar = try await client.createCalendar(
                name: "InterPrep Calendar",
                description: "Календарь собеседований"
            )
            self.selectedCalendar = newCalendar
            
            var settings = settingsManager.loadSettings()
            settings.selectedCalendarURL = newCalendar.url.absoluteString
            settingsManager.saveSettings(settings)
        }
    }
    
    func performFullSync(localEvents: [CalendarState.CalendarEvent]) async throws -> [CalendarState.CalendarEvent] {
        guard let client = client,
              let calendar = selectedCalendar else {
            throw CalDAVError.requestFailed
        }
        
        let startDate = Calendar.current.date(byAdding: .month, value: -3, to: Date())!
        let endDate = Calendar.current.date(byAdding: .month, value: 6, to: Date())!
        
        let serverEvents = try await client.fetchEvents(
            from: calendar,
            start: startDate,
            end: endDate
        )
        
        var mergedEvents = serverEvents.map { $0.toCalendarEvent() }
        
        for localEvent in localEvents {
            let existsOnServer = serverEvents.contains { $0.uid == localEvent.id }
            if !existsOnServer {
                let caldavEvent = CalDAVEvent.from(calendarEvent: localEvent)
                try await client.saveEvent(caldavEvent, to: calendar)
                mergedEvents.append(localEvent)
            }
        }
        
        var settings = settingsManager.loadSettings()
        settings.lastSyncDate = Date()
        settingsManager.saveSettings(settings)
        
        return mergedEvents
    }
    
    func pushEvent(_ event: CalendarState.CalendarEvent) async throws {
        guard let client = client,
              let calendar = selectedCalendar else {
            throw CalDAVError.requestFailed
        }
        
        let caldavEvent = CalDAVEvent.from(calendarEvent: event)
        try await client.saveEvent(caldavEvent, to: calendar)
    }
    
    func deleteEvent(_ event: CalendarState.CalendarEvent) async throws {
        guard let client = client,
              let calendar = selectedCalendar else {
            throw CalDAVError.requestFailed
        }
        
        let caldavEvent = CalDAVEvent.from(calendarEvent: event)
        try await client.deleteEvent(caldavEvent, from: calendar)
    }
    
    func testConnection() async throws -> Bool {
        guard let client = client else {
            throw CalDAVError.requestFailed
        }
        
        _ = try await client.discoverPrincipal()
        return true
    }
}
