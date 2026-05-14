import Foundation

public enum AnalyticsEvent: Sendable {
    case screenView(screen: Screen)

    case loginStarted
    case loginCompleted(method: String)
    case loginFailed(error: String)
    case registrationStarted
    case registrationCompleted
    case registrationFailed(error: String)
    case logout

    case resumeUploadStarted
    case resumeUploadCompleted(fileSize: Int)
    case resumeUploadFailed(error: String)
    case resumeViewed

    case vacancyViewed(vacancyId: String, company: String)
    case vacancyFavorited(vacancyId: String)
    case vacancyUnfavorited(vacancyId: String)
    case vacancyShared(vacancyId: String)
    case vacancySearched(query: String, filters: [String: String])

    case chatStarted(vacancyId: String?)
    case chatMessageSent(messageLength: Int)
    case chatCompleted(messagesCount: Int)

    case calendarEventCreated(eventId: String?)
    case calendarEventDeleted(eventId: String)
    case calendarSynced

    case profileEdited(fields: [String])
    case profilePhotoUploaded
    case settingsChanged(setting: String, value: String)

    case documentUploaded(type: String)
    case documentDeleted(type: String)
    case documentViewed(type: String)

    case appLaunched
    case appBackgrounded
    case appForegrounded
    case pushNotificationReceived(type: String)
    case pushNotificationOpened(type: String)
    case errorOccurred(domain: String, code: Int, message: String)
    case networkError(endpoint: String, statusCode: Int?)

    public enum Screen: String, Sendable {
        case onboarding = "onboarding"
        case login = "login"
        case registration = "registration"
        case passwordReset = "password_reset"
        case otp = "otp"
        case discovery = "discovery"
        case vacancyDetail = "vacancy_detail"
        case chat = "chat"
        case calendar = "calendar"
        case profile = "profile"
        case settings = "settings"
        case documents = "documents"
        case resumeUpload = "resume_upload"
        case resumeReview = "resume_review"
    }

    var name: String {
        switch self {
        case .screenView: return "screen_view"
        case .loginStarted: return "login_started"
        case .loginCompleted: return "login_completed"
        case .loginFailed: return "login_failed"
        case .registrationStarted: return "registration_started"
        case .registrationCompleted: return "registration_completed"
        case .registrationFailed: return "registration_failed"
        case .logout: return "logout"
        case .resumeUploadStarted: return "resume_upload_started"
        case .resumeUploadCompleted: return "resume_upload_completed"
        case .resumeUploadFailed: return "resume_upload_failed"
        case .resumeViewed: return "resume_viewed"
        case .vacancyViewed: return "vacancy_viewed"
        case .vacancyFavorited: return "vacancy_favorited"
        case .vacancyUnfavorited: return "vacancy_unfavorited"
        case .vacancyShared: return "vacancy_shared"
        case .vacancySearched: return "vacancy_searched"
        case .chatStarted: return "chat_started"
        case .chatMessageSent: return "chat_message_sent"
        case .chatCompleted: return "chat_completed"
        case .calendarEventCreated: return "calendar_event_created"
        case .calendarEventDeleted: return "calendar_event_deleted"
        case .calendarSynced: return "calendar_synced"
        case .profileEdited: return "profile_edited"
        case .profilePhotoUploaded: return "profile_photo_uploaded"
        case .settingsChanged: return "settings_changed"
        case .documentUploaded: return "document_uploaded"
        case .documentDeleted: return "document_deleted"
        case .documentViewed: return "document_viewed"
        case .appLaunched: return "app_launched"
        case .appBackgrounded: return "app_backgrounded"
        case .appForegrounded: return "app_foregrounded"
        case .pushNotificationReceived: return "push_notification_received"
        case .pushNotificationOpened: return "push_notification_opened"
        case .errorOccurred: return "error_occurred"
        case .networkError: return "network_error"
        }
    }

    var parameters: [String: Any] {
        switch self {
        case let .screenView(screen):
            return ["screen_name": screen.rawValue]

        case .loginStarted, .registrationStarted, .logout, .resumeUploadStarted,
             .resumeViewed, .calendarSynced, .profilePhotoUploaded,
             .appLaunched, .appBackgrounded, .appForegrounded:
            return [:]

        case let .loginCompleted(method):
            return ["method": method]

        case let .loginFailed(error), let .registrationFailed(error), let .resumeUploadFailed(error):
            return ["error": error]

        case .registrationCompleted:
            return [:]

        case let .resumeUploadCompleted(fileSize):
            return ["file_size": fileSize]

        case let .vacancyViewed(vacancyId, company):
            return ["vacancy_id": vacancyId, "company": company]

        case let .vacancyFavorited(vacancyId), let .vacancyUnfavorited(vacancyId),
             let .vacancyShared(vacancyId):
            return ["vacancy_id": vacancyId]

        case let .vacancySearched(query, filters):
            var params: [String: Any] = ["query": query]
            filters.forEach { params[$0.key] = $0.value }
            return params

        case let .chatStarted(vacancyId):
            return vacancyId.map { ["vacancy_id": $0] } ?? [:]

        case let .chatMessageSent(messageLength):
            return ["message_length": messageLength]

        case let .chatCompleted(messagesCount):
            return ["messages_count": messagesCount]

        case let .calendarEventCreated(eventId):
            return eventId.map { ["event_id": $0] } ?? [:]

        case let .calendarEventDeleted(eventId):
            return ["event_id": eventId]

        case let .profileEdited(fields):
            return ["fields": fields.joined(separator: ",")]

        case let .settingsChanged(setting, value):
            return ["setting": setting, "value": value]

        case let .documentUploaded(type), let .documentDeleted(type), let .documentViewed(type):
            return ["document_type": type]

        case let .pushNotificationReceived(type), let .pushNotificationOpened(type):
            return ["notification_type": type]

        case let .errorOccurred(domain, code, message):
            return ["domain": domain, "code": code, "message": message]

        case let .networkError(endpoint, statusCode):
            var params: [String: Any] = ["endpoint": endpoint]
            if let code = statusCode {
                params["status_code"] = code
            }
            return params
        }
    }
}

public struct AnalyticsUserProperties: Sendable {
    public var userId: String?
    public var email: String?
    public var hasResume: Bool?
    public var registrationDate: Date?
    public var appVersion: String?
    public var region: String?

    public init(
        userId: String? = nil,
        email: String? = nil,
        hasResume: Bool? = nil,
        registrationDate: Date? = nil,
        appVersion: String? = nil,
        region: String? = nil
    ) {
        self.userId = userId
        self.email = email
        self.hasResume = hasResume
        self.registrationDate = registrationDate
        self.appVersion = appVersion
        self.region = region
    }
}

public protocol AnalyticsServiceProtocol: Sendable {
    func configure(apiKey: String)
    func setEnabled(_ enabled: Bool)
    func track(_ event: AnalyticsEvent)
    func setUserProperties(_ properties: AnalyticsUserProperties)
    func setUserId(_ userId: String?)
    func resetUser()
}

@MainActor
public final class AnalyticsManager: @unchecked Sendable {
    public static let shared = AnalyticsManager()

    private var service: AnalyticsServiceProtocol?
    private var isEnabled: Bool = true
    private var pendingEvents: [AnalyticsEvent] = []

    private init() {}

    public func configure(service: AnalyticsServiceProtocol, apiKey: String) {
        self.service = service
        service.configure(apiKey: apiKey)

        pendingEvents.forEach { service.track($0) }
        pendingEvents.removeAll()
    }

    public func setEnabled(_ enabled: Bool) {
        isEnabled = enabled
        service?.setEnabled(enabled)
    }

    public func track(_ event: AnalyticsEvent) {
        guard isEnabled else { return }

        if let service = service {
            service.track(event)
        } else {
            pendingEvents.append(event)
        }
    }

    public func setUserProperties(_ properties: AnalyticsUserProperties) {
        service?.setUserProperties(properties)
    }

    public func setUserId(_ userId: String?) {
        service?.setUserId(userId)
    }

    public func resetUser() {
        service?.resetUser()
    }
}

public extension AnalyticsManager {
    func trackScreenView(_ screen: AnalyticsEvent.Screen) {
        track(.screenView(screen: screen))
    }

    func trackError(_ error: Error, domain: String = "app") {
        let nsError = error as NSError
        track(.errorOccurred(
            domain: domain,
            code: nsError.code,
            message: nsError.localizedDescription
        ))
    }
}
