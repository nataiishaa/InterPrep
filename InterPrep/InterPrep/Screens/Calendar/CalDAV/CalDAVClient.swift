//
//  CalDAVClient.swift
//  InterPrep
//
//  CalDAV client implementation (RFC 4791)
//

import Foundation

/// CalDAV client for calendar synchronization
public final class CalDAVClient {
    
    // MARK: - Properties
    
    private let serverURL: URL
    private let username: String
    private let password: String
    private let session: URLSession
    
    private var principalURL: URL?
    private var calendarHomeURL: URL?
    
    // MARK: - Initialization
    
    public init(serverURL: URL, username: String, password: String) {
        self.serverURL = serverURL
        self.username = username
        self.password = password
        
        let config = URLSessionConfiguration.default
        config.httpAdditionalHeaders = [
            "User-Agent": "InterPrep/1.0",
            "Content-Type": "application/xml; charset=utf-8"
        ]
        self.session = URLSession(configuration: config)
    }
    
    // MARK: - Discovery
    
    /// Step 1: Discover principal URL
    func discoverPrincipal() async throws -> URL {
        let request = createRequest(
            method: "PROPFIND",
            url: serverURL,
            body: """
            <?xml version="1.0" encoding="utf-8" ?>
            <d:propfind xmlns:d="DAV:">
                <d:prop>
                    <d:current-user-principal/>
                </d:prop>
            </d:propfind>
            """
        )
        
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw CalDAVError.discoveryFailed
        }
        
        let parser = XMLParser(data: data)
        let delegate = PrincipalParserDelegate()
        parser.delegate = delegate
        parser.parse()
        
        guard let principalPath = delegate.principalPath else {
            throw CalDAVError.principalNotFound
        }
        
        let principal = serverURL.appendingPathComponent(principalPath)
        self.principalURL = principal
        return principal
    }
    
    func discoverCalendarHome() async throws -> URL {
        guard let principalURL = principalURL else {
            throw CalDAVError.principalNotFound
        }
        
        let request = createRequest(
            method: "PROPFIND",
            url: principalURL,
            body: """
            <?xml version="1.0" encoding="utf-8" ?>
            <d:propfind xmlns:d="DAV:" xmlns:c="urn:ietf:params:xml:ns:caldav">
                <d:prop>
                    <c:calendar-home-set/>
                </d:prop>
            </d:propfind>
            """
        )
        
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw CalDAVError.discoveryFailed
        }
        
        let parser = XMLParser(data: data)
        let delegate = CalendarHomeParserDelegate()
        parser.delegate = delegate
        parser.parse()
        
        guard let calendarHomePath = delegate.calendarHomePath else {
            throw CalDAVError.calendarHomeNotFound
        }
        
        let calendarHome = serverURL.appendingPathComponent(calendarHomePath)
        self.calendarHomeURL = calendarHome
        return calendarHome
    }
    
    /// Step 3: List calendars
    func listCalendars() async throws -> [CalDAVCalendar] {
        guard let calendarHomeURL = calendarHomeURL else {
            throw CalDAVError.calendarHomeNotFound
        }
        
        let request = createRequest(
            method: "PROPFIND",
            url: calendarHomeURL,
            depth: "1",
            body: """
            <?xml version="1.0" encoding="utf-8" ?>
            <d:propfind xmlns:d="DAV:" xmlns:c="urn:ietf:params:xml:ns:caldav">
                <d:prop>
                    <d:resourcetype/>
                    <d:displayname/>
                    <c:calendar-description/>
                    <c:supported-calendar-component-set/>
                </d:prop>
            </d:propfind>
            """
        )
        
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw CalDAVError.requestFailed
        }
        
        let parser = XMLParser(data: data)
        let delegate = CalendarsParserDelegate()
        parser.delegate = delegate
        parser.parse()
        
        return delegate.calendars.map { info in
            CalDAVCalendar(
                url: serverURL.appendingPathComponent(info.href),
                displayName: info.displayName,
                description: info.description
            )
        }
    }
    
    // MARK: - Calendar Operations
    
    /// Create a new calendar
    func createCalendar(name: String, description: String? = nil) async throws -> CalDAVCalendar {
        guard let calendarHomeURL = calendarHomeURL else {
            throw CalDAVError.calendarHomeNotFound
        }
        
        let calendarURL = calendarHomeURL.appendingPathComponent(UUID().uuidString)
        
        let descriptionXML = description.map { "<C:calendar-description>\($0)</C:calendar-description>" } ?? ""
        
        let request = createRequest(
            method: "MKCALENDAR",
            url: calendarURL,
            body: """
            <?xml version="1.0" encoding="utf-8" ?>
            <C:mkcalendar xmlns:D="DAV:" xmlns:C="urn:ietf:params:xml:ns:caldav">
                <D:set>
                    <D:prop>
                        <D:displayname>\(name)</D:displayname>
                        \(descriptionXML)
                        <C:supported-calendar-component-set>
                            <C:comp name="VEVENT"/>
                        </C:supported-calendar-component-set>
                    </D:prop>
                </D:set>
            </C:mkcalendar>
            """
        )
        
        let (_, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw CalDAVError.createFailed
        }
        
        return CalDAVCalendar(url: calendarURL, displayName: name, description: description)
    }
    
    // MARK: - Event Operations
    
    /// Fetch events in date range
    func fetchEvents(from calendar: CalDAVCalendar, start: Date, end: Date) async throws -> [CalDAVEvent] {
        let startString = ISO8601DateFormatter().string(from: start)
        let endString = ISO8601DateFormatter().string(from: end)
        
        let request = createRequest(
            method: "REPORT",
            url: calendar.url,
            depth: "1",
            body: """
            <?xml version="1.0" encoding="utf-8" ?>
            <C:calendar-query xmlns:D="DAV:" xmlns:C="urn:ietf:params:xml:ns:caldav">
                <D:prop>
                    <D:getetag/>
                    <C:calendar-data/>
                </D:prop>
                <C:filter>
                    <C:comp-filter name="VCALENDAR">
                        <C:comp-filter name="VEVENT">
                            <C:time-range start="\(startString)" end="\(endString)"/>
                        </C:comp-filter>
                    </C:comp-filter>
                </C:filter>
            </C:calendar-query>
            """
        )
        
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw CalDAVError.requestFailed
        }
        
        let parser = XMLParser(data: data)
        let delegate = EventsParserDelegate()
        parser.delegate = delegate
        parser.parse()
        
        return delegate.events.compactMap { eventData in
            try? ICalendarParser.parse(eventData.calendarData)
        }
    }
    
    /// Create or update event
    func saveEvent(_ event: CalDAVEvent, to calendar: CalDAVCalendar) async throws {
        let eventURL = calendar.url.appendingPathComponent("\(event.uid).ics")
        let icsData = ICalendarGenerator.generate(event)
        
        var request = createRequest(method: "PUT", url: eventURL, body: nil)
        request.httpBody = icsData.data(using: .utf8)
        request.setValue("text/calendar; charset=utf-8", forHTTPHeaderField: "Content-Type")
        
        if let etag = event.etag {
            request.setValue(etag, forHTTPHeaderField: "If-Match")
        }
        
        let (_, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw CalDAVError.saveFailed
        }
    }
    
    /// Delete event
    func deleteEvent(_ event: CalDAVEvent, from calendar: CalDAVCalendar) async throws {
        let eventURL = calendar.url.appendingPathComponent("\(event.uid).ics")
        
        var request = createRequest(method: "DELETE", url: eventURL, body: nil)
        if let etag = event.etag {
            request.setValue(etag, forHTTPHeaderField: "If-Match")
        }
        
        let (_, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw CalDAVError.deleteFailed
        }
    }
    
    // MARK: - Helpers
    
    private func createRequest(
        method: String,
        url: URL,
        depth: String? = nil,
        body: String?
    ) -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = method
        
        // Basic Auth
        let credentials = "\(username):\(password)"
        if let credentialsData = credentials.data(using: .utf8) {
            let base64Credentials = credentialsData.base64EncodedString()
            request.setValue("Basic \(base64Credentials)", forHTTPHeaderField: "Authorization")
        }
        
        if let depth = depth {
            request.setValue(depth, forHTTPHeaderField: "Depth")
        }
        
        if let body = body {
            request.httpBody = body.data(using: .utf8)
        }
        
        return request
    }
}

// MARK: - Models

struct CalDAVCalendar {
    let url: URL
    let displayName: String
    let description: String?
}

struct CalDAVEvent {
    let uid: String
    let summary: String
    let description: String?
    let startDate: Date
    let endDate: Date?
    let location: String?
    var etag: String?
}

// MARK: - Errors

enum CalDAVError: LocalizedError {
    case discoveryFailed
    case principalNotFound
    case calendarHomeNotFound
    case requestFailed
    case createFailed
    case saveFailed
    case deleteFailed
    case parseError
    
    var errorDescription: String? {
        switch self {
        case .discoveryFailed: return "Не удалось обнаружить сервер"
        case .principalNotFound: return "Principal URL не найден"
        case .calendarHomeNotFound: return "Calendar Home не найден"
        case .requestFailed: return "Ошибка запроса"
        case .createFailed: return "Не удалось создать календарь"
        case .saveFailed: return "Не удалось сохранить событие"
        case .deleteFailed: return "Не удалось удалить событие"
        case .parseError: return "Ошибка парсинга"
        }
    }
}

// MARK: - XML Parser Delegates

private class PrincipalParserDelegate: NSObject, XMLParserDelegate {
    var principalPath: String?
    private var currentElement = ""
    private var currentValue = ""
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        currentElement = elementName
        currentValue = ""
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        currentValue += string
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == "href" && currentElement == "href" {
            principalPath = currentValue.trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }
}

private class CalendarHomeParserDelegate: NSObject, XMLParserDelegate {
    var calendarHomePath: String?
    private var currentElement = ""
    private var currentValue = ""
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        currentElement = elementName
        currentValue = ""
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        currentValue += string
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == "href" && currentElement == "href" {
            calendarHomePath = currentValue.trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }
}

private class CalendarsParserDelegate: NSObject, XMLParserDelegate {
    struct CalendarInfo {
        var href: String = ""
        var displayName: String = ""
        var description: String = ""
    }
    
    var calendars: [CalendarInfo] = []
    private var currentCalendar = CalendarInfo()
    private var currentElement = ""
    private var currentValue = ""
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        currentElement = elementName
        currentValue = ""
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        currentValue += string
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        let trimmed = currentValue.trimmingCharacters(in: .whitespacesAndNewlines)
        
        switch elementName {
        case "href":
            currentCalendar.href = trimmed
        case "displayname":
            currentCalendar.displayName = trimmed
        case "calendar-description":
            currentCalendar.description = trimmed
        case "response":
            if !currentCalendar.href.isEmpty {
                calendars.append(currentCalendar)
            }
            currentCalendar = CalendarInfo()
        default:
            break
        }
    }
}

private class EventsParserDelegate: NSObject, XMLParserDelegate {
    struct EventData {
        var href: String = ""
        var etag: String = ""
        var calendarData: String = ""
    }
    
    var events: [EventData] = []
    private var currentEvent = EventData()
    private var currentElement = ""
    private var currentValue = ""
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        currentElement = elementName
        currentValue = ""
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        currentValue += string
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        let trimmed = currentValue.trimmingCharacters(in: .whitespacesAndNewlines)
        
        switch elementName {
        case "href":
            currentEvent.href = trimmed
        case "getetag":
            currentEvent.etag = trimmed
        case "calendar-data":
            currentEvent.calendarData = trimmed
        case "response":
            if !currentEvent.href.isEmpty {
                events.append(currentEvent)
            }
            currentEvent = EventData()
        default:
            break
        }
    }
}
