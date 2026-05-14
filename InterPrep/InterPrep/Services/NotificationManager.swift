import Foundation
import UIKit
import UserNotifications

@MainActor
public final class NotificationManager: NSObject, ObservableObject {
    public static let shared = NotificationManager()

    @Published public private(set) var isAuthorized = false
    @Published public private(set) var authorizationStatus: UNAuthorizationStatus = .notDetermined
    @Published public var isEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isEnabled, forKey: "notifications_enabled")
            if !isEnabled {
                cancelAllLocalNotifications()
            }
        }
    }

    private let notificationCenter = UNUserNotificationCenter.current()

    private override init() {
        self.isEnabled = UserDefaults.standard.bool(forKey: "notifications_enabled")
        if UserDefaults.standard.object(forKey: "notifications_enabled") == nil {
            self.isEnabled = true
            UserDefaults.standard.set(true, forKey: "notifications_enabled")
        }

        super.init()
        notificationCenter.delegate = self
        registerNotificationCategories()
    }

    public func requestAuthorization() async -> Bool {
        do {
            let granted = try await notificationCenter.requestAuthorization(options: [.alert, .sound, .badge])
            self.isAuthorized = granted
            self.authorizationStatus = granted ? .authorized : .denied
            return granted
        } catch {
            self.authorizationStatus = .denied
            return false
        }
    }

    public func checkAuthorizationStatus() async {
        let settings = await notificationCenter.notificationSettings()
        self.authorizationStatus = settings.authorizationStatus
        self.isAuthorized = settings.authorizationStatus == .authorized
    }

    public var needsPermissionRequest: Bool {
        authorizationStatus == .notDetermined
    }

    public var isDenied: Bool {
        authorizationStatus == .denied
    }

    public func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            Task { @MainActor in
                await UIApplication.shared.open(url)
            }
        }
    }

    private func registerNotificationCategories() {
        let viewAction = UNNotificationAction(
            identifier: "VIEW_ACTION",
            title: "Открыть",
            options: [.foreground]
        )

        let dismissAction = UNNotificationAction(
            identifier: "DISMISS_ACTION",
            title: "Закрыть",
            options: [.destructive]
        )

        let eventCategory = UNNotificationCategory(
            identifier: "EVENT_REMINDER",
            actions: [viewAction, dismissAction],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )

        let interviewCategory = UNNotificationCategory(
            identifier: "INTERVIEW_REMINDER",
            actions: [viewAction, dismissAction],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )

        notificationCenter.setNotificationCategories([eventCategory, interviewCategory])
    }

    public func scheduleLocalNotification(
        id: String,
        title: String,
        body: String,
        subtitle: String? = nil,
        triggerDate: Date,
        categoryIdentifier: String = "EVENT_REMINDER",
        userInfo: [AnyHashable: Any] = [:]
    ) async throws {
        guard isEnabled else {
            throw NotificationError.notificationsDisabled
        }

        guard isAuthorized else {
            throw NotificationError.notAuthorized
        }

        guard triggerDate > Date() else {
            throw NotificationError.invalidTriggerDate
        }

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.categoryIdentifier = categoryIdentifier
        content.userInfo = userInfo

        if let subtitle = subtitle {
            content.subtitle = subtitle
        }

        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: triggerDate
        )

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        let request = UNNotificationRequest(
            identifier: id,
            content: content,
            trigger: trigger
        )

        try await notificationCenter.add(request)
    }

    public func scheduleIntervalNotification(
        id: String,
        title: String,
        body: String,
        timeInterval: TimeInterval,
        repeats: Bool = false,
        userInfo: [AnyHashable: Any] = [:]
    ) async throws {
        guard isEnabled else {
            throw NotificationError.notificationsDisabled
        }

        guard isAuthorized else {
            throw NotificationError.notAuthorized
        }

        guard timeInterval > 0 else {
            throw NotificationError.invalidTriggerDate
        }

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.userInfo = userInfo

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: repeats)

        let request = UNNotificationRequest(
            identifier: id,
            content: content,
            trigger: trigger
        )

        try await notificationCenter.add(request)
    }

    public func cancelLocalNotification(id: String) {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [id])
    }

    public func cancelAllLocalNotifications() {
        notificationCenter.removeAllPendingNotificationRequests()
    }

    public func getPendingNotifications() async -> [UNNotificationRequest] {
        return await notificationCenter.pendingNotificationRequests()
    }

    public func getDeliveredNotifications() async -> [UNNotification] {
        return await notificationCenter.deliveredNotifications()
    }

    public func removeDeliveredNotification(id: String) {
        notificationCenter.removeDeliveredNotifications(withIdentifiers: [id])
    }

    public func removeAllDeliveredNotifications() {
        notificationCenter.removeAllDeliveredNotifications()
    }

    public func setBadgeCount(_ count: Int) async {
        do {
            try await notificationCenter.setBadgeCount(count)
        } catch {
        }
    }
}

public enum NotificationError: LocalizedError {
    case notificationsDisabled
    case notAuthorized
    case invalidTriggerDate
    case schedulingFailed(Error)

    public var errorDescription: String? {
        switch self {
        case .notificationsDisabled:
            return "Уведомления отключены в настройках приложения"
        case .notAuthorized:
            return "Нет разрешения на отправку уведомлений"
        case .invalidTriggerDate:
            return "Некорректная дата уведомления"
        case .schedulingFailed(let error):
            return "Не удалось запланировать уведомление: \(error.localizedDescription)"
        }
    }
}

extension NotificationManager: UNUserNotificationCenterDelegate {
    public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .badge])
    }

    public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        let actionIdentifier = response.actionIdentifier

        switch actionIdentifier {
        case UNNotificationDefaultActionIdentifier, "VIEW_ACTION":
            if let eventId = userInfo["event_id"] as? String {
                NotificationCenter.default.post(
                    name: .openCalendarEvent,
                    object: nil,
                    userInfo: ["eventId": eventId]
                )
            }

            if let vacancyId = userInfo["vacancy_id"] as? String {
                NotificationCenter.default.post(
                    name: .openVacancy,
                    object: nil,
                    userInfo: ["vacancyId": vacancyId]
                )
            }

            if let chatId = userInfo["chat_id"] as? String {
                NotificationCenter.default.post(
                    name: .openChat,
                    object: nil,
                    userInfo: ["chatId": chatId]
                )
            }

        case "DISMISS_ACTION":
            break

        default:
            break
        }

        completionHandler()
    }
}

public extension Notification.Name {
    static let openCalendarEvent = Notification.Name("openCalendarEvent")
    static let openVacancy = Notification.Name("openVacancy")
    static let openChat = Notification.Name("openChat")
}
