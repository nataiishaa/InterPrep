import Foundation

final class CalDAVSyncManager {

    private let settingsManager = CalDAVSettingsManager.shared
    private var client: CalDAVClient?
    private var selectedCalendar: CalDAVCalendar?

    func setup() async throws {
        let settings = settingsManager.loadSettings()
        guard let client = settingsManager.createClient(from: settings) else {
            throw CalDAVError.networkError("Заполните все поля: сервер, логин и пароль")
        }

        self.client = client
        try await discoverAndSelectCalendar()
    }

    private func discoverAndSelectCalendar() async throws {
        guard let client = client else { return }

        _ = try await client.discoverPrincipal()
        _ = try await client.discoverCalendarHome()

        let settings = settingsManager.loadSettings()
        if let calendarURLString = settings.selectedCalendarURL,
           let calendarURL = URL(string: calendarURLString) {
            self.selectedCalendar = CalDAVCalendar(
                url: calendarURL,
                displayName: "InterPrep Calendar",
                description: nil
            )
            return
        }

        let calendars = try await client.listCalendars()

        if let firstCalendar = calendars.first {
            self.selectedCalendar = firstCalendar

            var updatedSettings = settings
            updatedSettings.selectedCalendarURL = firstCalendar.url.absoluteString
            settingsManager.saveSettings(updatedSettings)
        } else {
            let newCalendar = try await client.createCalendar(
                name: "InterPrep Calendar",
                description: "Календарь собеседований"
            )
            self.selectedCalendar = newCalendar

            var updatedSettings = settings
            updatedSettings.selectedCalendarURL = newCalendar.url.absoluteString
            settingsManager.saveSettings(updatedSettings)
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

}
