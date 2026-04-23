import Foundation
import UIKit
import UserNotifications

@MainActor
public final class NotificationManager: NSObject, ObservableObject {
    public static let shared = NotificationManager()
    
    @Published public private(set) var isAuthorized = false
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
    }
    
    // MARK: - Permission Request
    
    public func requestAuthorization() async -> Bool {
        do {
            let granted = try await notificationCenter.requestAuthorization(options: [.alert, .sound, .badge])
            self.isAuthorized = granted
            return granted
        } catch {
            return false
        }
    }
    
    public func checkAuthorizationStatus() async {
        let settings = await notificationCenter.notificationSettings()
        self.isAuthorized = settings.authorizationStatus == .authorized
    }
    
    public func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            Task { @MainActor in
                await UIApplication.shared.open(url)
            }
        }
    }
    
    // MARK: - Local Notifications
    
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
            return
        }
        
        guard isAuthorized else {
            return
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
    
    public func cancelLocalNotification(id: String) {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [id])
    }
    
    public func cancelAllLocalNotifications() {
        notificationCenter.removeAllPendingNotificationRequests()
    }
    
    public func getPendingNotifications() async -> [UNNotificationRequest] {
        return await notificationCenter.pendingNotificationRequests()
    }
}

// MARK: - UNUserNotificationCenterDelegate

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
        
        if let eventId = userInfo["event_id"] as? String {
            NotificationCenter.default.post(
                name: .openCalendarEvent,
                object: nil,
                userInfo: ["eventId": eventId]
            )
        }
        
        completionHandler()
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let openCalendarEvent = Notification.Name("openCalendarEvent")
}
