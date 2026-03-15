//
//  CalDAVSyncManager.swift
//  InterPrep
//
//  CalDAV synchronization manager
//

import Foundation

final class CalDAVSyncManager {
    
    // MARK: - Properties
    
    private let settingsManager = CalDAVSettingsManager.shared
    private var client: CalDAVClient?
    private var selectedCalendar: CalDAVCalendar?
    
    // MARK: - Setup
    
    func setup() async throws {
        let settings = settingsManager.loadSettings()
        guard let client = settingsManager.createClient(from: settings) else {
            throw CalDAVError.requestFailed
        }
        
        self.client = client
        
        // Discover calendar if not set
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
        
        // Step 1: Discover principal
        _ = try await client.discoverPrincipal()
        
        // Step 2: Discover calendar home
        _ = try await client.discoverCalendarHome()
        
        // Step 3: List calendars
        let calendars = try await client.listCalendars()
        
        // Select first calendar or create new one
        if let firstCalendar = calendars.first {
            self.selectedCalendar = firstCalendar
            
            var settings = settingsManager.loadSettings()
            settings.selectedCalendarURL = firstCalendar.url.absoluteString
            settingsManager.saveSettings(settings)
        } else {
            // Create new calendar
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
    
    // MARK: - Sync Operations
    
    /// Full sync: pull events from server and push local changes
    func performFullSync(localEvents: [CalendarState.CalendarEvent]) async throws -> [CalendarState.CalendarEvent] {
        guard let client = client,
              let calendar = selectedCalendar else {
            throw CalDAVError.requestFailed
        }
        
        // Fetch events from server (last 3 months to future 6 months)
        let startDate = Calendar.current.date(byAdding: .month, value: -3, to: Date())!
        let endDate = Calendar.current.date(byAdding: .month, value: 6, to: Date())!
        
        let serverEvents = try await client.fetchEvents(
            from: calendar,
            start: startDate,
            end: endDate
        )
        
        // Convert to local format
        var mergedEvents = serverEvents.map { $0.toCalendarEvent() }
        
        // Push local events that don't exist on server
        for localEvent in localEvents {
            let existsOnServer = serverEvents.contains { $0.uid == localEvent.id }
            if !existsOnServer {
                let caldavEvent = CalDAVEvent.from(calendarEvent: localEvent)
                try await client.saveEvent(caldavEvent, to: calendar)
                mergedEvents.append(localEvent)
            }
        }
        
        // Update last sync date
        var settings = settingsManager.loadSettings()
        settings.lastSyncDate = Date()
        settingsManager.saveSettings(settings)
        
        return mergedEvents
    }
    
    /// Push single event to server
    func pushEvent(_ event: CalendarState.CalendarEvent) async throws {
        guard let client = client,
              let calendar = selectedCalendar else {
            throw CalDAVError.requestFailed
        }
        
        let caldavEvent = CalDAVEvent.from(calendarEvent: event)
        try await client.saveEvent(caldavEvent, to: calendar)
    }
    
    /// Delete event from server
    func deleteEvent(_ event: CalendarState.CalendarEvent) async throws {
        guard let client = client,
              let calendar = selectedCalendar else {
            throw CalDAVError.requestFailed
        }
        
        let caldavEvent = CalDAVEvent.from(calendarEvent: event)
        try await client.deleteEvent(caldavEvent, from: calendar)
    }
    
    /// Test connection
    func testConnection() async throws -> Bool {
        guard let client = client else {
            throw CalDAVError.requestFailed
        }
        
        _ = try await client.discoverPrincipal()
        return true
    }
}
