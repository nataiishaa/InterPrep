import Foundation

// swiftlint:disable file_length
public final class CalDAVClient: NSObject, URLSessionTaskDelegate {
    private let serverURL: URL
    private let username: String
    private let password: String
    private var session: URLSession!

    private var principalURL: URL?
    private var calendarHomeURL: URL?

    public init(serverURL: URL, username: String, password: String) {
        self.serverURL = serverURL
        self.username = username
        self.password = password

        super.init()

        let config = URLSessionConfiguration.default
        config.httpAdditionalHeaders = [
            "User-Agent": "InterPrep/1.0",
            "Content-Type": "application/xml; charset=utf-8"
        ]
        self.session = URLSession(configuration: config, delegate: self, delegateQueue: nil)
    }

    public func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodHTTPBasic ||
           challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodHTTPDigest {
            let credential = URLCredential(
                user: username,
                password: password,
                persistence: .forSession
            )
            completionHandler(.useCredential, credential)
        } else if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
                  let serverTrust = challenge.protectionSpace.serverTrust {
            let credential = URLCredential(trust: serverTrust)
            completionHandler(.useCredential, credential)
        } else {
            completionHandler(.performDefaultHandling, nil)
        }
    }

    func discoverPrincipal() async throws -> URL {
        let request = createRequest(
            method: "PROPFIND",
            url: serverURL,
            depth: "0",
            body: """
            <?xml version="1.0" encoding="utf-8" ?>
            <d:propfind xmlns:d="DAV:">
                <d:prop>
                    <d:current-user-principal/>
                </d:prop>
            </d:propfind>
            """
        )

        let (data, response) = try await performRequest(request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw CalDAVError.discoveryFailed
        }

        guard (200...299).contains(httpResponse.statusCode) || httpResponse.statusCode == 207 else {
            if httpResponse.statusCode == 401 {
                throw CalDAVError.networkError("Неверные логин или пароль")
            } else if httpResponse.statusCode == 404 {
                throw CalDAVError.networkError("Сервер не найден по указанному адресу")
            }
            throw CalDAVError.discoveryFailed
        }

        let parser = XMLParser(data: data)
        let delegate = PrincipalParserDelegate()
        parser.delegate = delegate
        parser.parse()

        guard let principalPath = delegate.principalPath else {
            throw CalDAVError.principalNotFound
        }

        let principal = resolveURL(principalPath)
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
            depth: "0",
            body: """
            <?xml version="1.0" encoding="utf-8" ?>
            <d:propfind xmlns:d="DAV:" xmlns:c="urn:ietf:params:xml:ns:caldav">
                <d:prop>
                    <c:calendar-home-set/>
                </d:prop>
            </d:propfind>
            """
        )

        let (data, response) = try await performRequest(request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw CalDAVError.discoveryFailed
        }

        guard (200...299).contains(httpResponse.statusCode) || httpResponse.statusCode == 207 else {
            if httpResponse.statusCode == 401 {
                throw CalDAVError.networkError("Неверные логин или пароль")
            }
            throw CalDAVError.discoveryFailed
        }

        let parser = XMLParser(data: data)
        let delegate = CalendarHomeParserDelegate()
        parser.delegate = delegate
        parser.parse()

        guard let calendarHomePath = delegate.calendarHomePath else {
            throw CalDAVError.calendarHomeNotFound
        }

        let calendarHome = resolveURL(calendarHomePath)
        self.calendarHomeURL = calendarHome
        return calendarHome
    }

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

        let (data, response) = try await performRequest(request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw CalDAVError.requestFailed
        }

        guard (200...299).contains(httpResponse.statusCode) || httpResponse.statusCode == 207 else {
            if httpResponse.statusCode == 401 {
                throw CalDAVError.networkError("Неверные логин или пароль")
            }
            throw CalDAVError.requestFailed
        }

        let parser = XMLParser(data: data)
        let delegate = CalendarsParserDelegate()
        parser.delegate = delegate
        parser.parse()

        return delegate.calendars.map { info in
            CalDAVCalendar(
                url: resolveURL(info.href),
                displayName: info.displayName,
                description: info.description
            )
        }
    }

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

        let (_, response) = try await performRequest(request)
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw CalDAVError.createFailed
        }

        return CalDAVCalendar(url: calendarURL, displayName: name, description: description)
    }

    func fetchEvents(from calendar: CalDAVCalendar, start: Date, end: Date) async throws -> [CalDAVEvent] {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd'T'HHmmss'Z'"
        formatter.timeZone = TimeZone(identifier: "UTC")
        let startString = formatter.string(from: start)
        let endString = formatter.string(from: end)

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

        let (data, response) = try await performRequest(request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw CalDAVError.requestFailed
        }

        guard (200...299).contains(httpResponse.statusCode) || httpResponse.statusCode == 207 else {
            if httpResponse.statusCode == 401 {
                throw CalDAVError.networkError("Неверные логин или пароль")
            }
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

    func saveEvent(_ event: CalDAVEvent, to calendar: CalDAVCalendar) async throws {
        let eventURL = calendar.url.appendingPathComponent("\(event.uid).ics")
        let icsData = ICalendarGenerator.generate(event)

        var request = createRequest(method: "PUT", url: eventURL, body: nil)
        request.httpBody = icsData.data(using: .utf8)
        request.setValue("text/calendar; charset=utf-8", forHTTPHeaderField: "Content-Type")

        if let etag = event.etag {
            request.setValue(etag, forHTTPHeaderField: "If-Match")
        }

        let (_, response) = try await performRequest(request)
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw CalDAVError.saveFailed
        }
    }

    func deleteEvent(_ event: CalDAVEvent, from calendar: CalDAVCalendar) async throws {
        let eventURL = calendar.url.appendingPathComponent("\(event.uid).ics")

        var request = createRequest(method: "DELETE", url: eventURL, body: nil)
        if let etag = event.etag {
            request.setValue(etag, forHTTPHeaderField: "If-Match")
        }

        let (_, response) = try await performRequest(request)
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw CalDAVError.deleteFailed
        }
    }

    private func performRequest(_ request: URLRequest) async throws -> (Data, URLResponse) {
        do {
            return try await session.data(for: request)
        } catch let urlError as URLError {
            switch urlError.code {
            case .notConnectedToInternet, .networkConnectionLost:
                throw CalDAVError.networkError("Нет подключения к интернету")
            case .timedOut:
                throw CalDAVError.networkError("Превышено время ожидания ответа от сервера")
            case .cannotFindHost:
                throw CalDAVError.networkError("Сервер не найден. Проверьте адрес: \(request.url?.host ?? "")")
            case .secureConnectionFailed, .serverCertificateUntrusted:
                throw CalDAVError.networkError("Ошибка SSL-соединения. Проверьте, что адрес начинается с https://")
            case .userAuthenticationRequired, .userCancelledAuthentication:
                throw CalDAVError.networkError("Неверные логин или пароль. Для iCloud используйте пароль приложения, не основной пароль Apple ID")
            default:
                throw CalDAVError.networkError(urlError.localizedDescription)
            }
        }
    }

    private func resolveURL(_ path: String) -> URL {
        if let absolute = URL(string: path), absolute.scheme != nil {
            return absolute
        }
        if path.hasPrefix("/") {
            var components = URLComponents(url: serverURL, resolvingAgainstBaseURL: false)!
            components.path = path
            return components.url ?? serverURL.appendingPathComponent(path)
        }
        return serverURL.appendingPathComponent(path)
    }

    private func createRequest(
        method: String,
        url: URL,
        depth: String? = nil,
        body: String?
    ) -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = method

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

enum CalDAVError: LocalizedError {
    case discoveryFailed
    case principalNotFound
    case calendarHomeNotFound
    case requestFailed
    case createFailed
    case saveFailed
    case deleteFailed
    case parseError
    case networkError(String)

    var errorDescription: String? {
        switch self {
        case .discoveryFailed: return "Не удалось обнаружить сервер. Проверьте адрес сервера и данные для входа."
        case .principalNotFound: return "Сервер не вернул Principal URL. Возможно, неверный адрес или логин."
        case .calendarHomeNotFound: return "Calendar Home не найден на сервере."
        case .requestFailed: return "Ошибка запроса к серверу CalDAV."
        case .createFailed: return "Не удалось создать календарь на сервере."
        case .saveFailed: return "Не удалось сохранить событие на сервере."
        case .deleteFailed: return "Не удалось удалить событие на сервере."
        case .parseError: return "Ошибка разбора ответа от сервера."
        case .networkError(let detail): return "Ошибка сети: \(detail)"
        }
    }
}

private class PrincipalParserDelegate: NSObject, XMLParserDelegate {
    var principalPath: String?
    private var currentValue = ""
    private var insideCurrentUserPrincipal = false
    private var insideHref = false

    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String: String] = [:]) {
        let localName = elementName.components(separatedBy: ":").last ?? elementName
        if localName == "current-user-principal" {
            insideCurrentUserPrincipal = true
        } else if localName == "href" && insideCurrentUserPrincipal {
            insideHref = true
            currentValue = ""
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        if insideHref {
            currentValue += string
        }
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        let localName = elementName.components(separatedBy: ":").last ?? elementName
        if localName == "href" && insideHref {
            insideHref = false
            if principalPath == nil {
                principalPath = currentValue.trimmingCharacters(in: .whitespacesAndNewlines)
            }
        } else if localName == "current-user-principal" {
            insideCurrentUserPrincipal = false
        }
    }
}

private class CalendarHomeParserDelegate: NSObject, XMLParserDelegate {
    var calendarHomePath: String?
    private var currentValue = ""
    private var insideCalendarHomeSet = false
    private var insideHref = false

    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String: String] = [:]) {
        let localName = elementName.components(separatedBy: ":").last ?? elementName
        if localName == "calendar-home-set" {
            insideCalendarHomeSet = true
        } else if localName == "href" && insideCalendarHomeSet {
            insideHref = true
            currentValue = ""
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        if insideHref {
            currentValue += string
        }
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        let localName = elementName.components(separatedBy: ":").last ?? elementName
        if localName == "href" && insideHref {
            insideHref = false
            if calendarHomePath == nil {
                calendarHomePath = currentValue.trimmingCharacters(in: .whitespacesAndNewlines)
            }
        } else if localName == "calendar-home-set" {
            insideCalendarHomeSet = false
        }
    }
}

private class CalendarsParserDelegate: NSObject, XMLParserDelegate {
    struct CalendarInfo {
        var href: String = ""
        var displayName: String = ""
        var description: String = ""
        var isCalendar: Bool = false
        var supportsVEVENT: Bool = false
    }

    var calendars: [CalendarInfo] = []
    private var currentCalendar = CalendarInfo()
    private var currentElement = ""
    private var currentValue = ""
    private var insideResourceType = false

    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String: String] = [:]) {
        let localName = elementName.components(separatedBy: ":").last ?? elementName
        currentElement = localName
        currentValue = ""

        if localName == "resourcetype" {
            insideResourceType = true
        } else if insideResourceType && localName == "calendar" {
            currentCalendar.isCalendar = true
        }

        if localName == "comp" {
            if let compName = attributeDict["name"], compName == "VEVENT" {
                currentCalendar.supportsVEVENT = true
            }
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        currentValue += string
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        let localName = elementName.components(separatedBy: ":").last ?? elementName
        let trimmed = currentValue.trimmingCharacters(in: .whitespacesAndNewlines)

        switch localName {
        case "href":
            if currentCalendar.href.isEmpty {
                currentCalendar.href = trimmed
            }
        case "displayname":
            currentCalendar.displayName = trimmed
        case "calendar-description":
            currentCalendar.description = trimmed
        case "resourcetype":
            insideResourceType = false
        case "response":
            if !currentCalendar.href.isEmpty && currentCalendar.isCalendar {
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

    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String: String] = [:]) {
        let localName = elementName.components(separatedBy: ":").last ?? elementName
        currentElement = localName
        currentValue = ""
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        currentValue += string
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        let localName = elementName.components(separatedBy: ":").last ?? elementName
        let trimmed = currentValue.trimmingCharacters(in: .whitespacesAndNewlines)

        switch localName {
        case "href":
            if currentEvent.href.isEmpty {
                currentEvent.href = trimmed
            }
        case "getetag":
            currentEvent.etag = trimmed
        case "calendar-data":
            currentEvent.calendarData = trimmed
        case "response":
            if !currentEvent.calendarData.isEmpty {
                events.append(currentEvent)
            }
            currentEvent = EventData()
        default:
            break
        }
    }
}
