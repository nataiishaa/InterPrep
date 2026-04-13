import UIKit
import UserNotifications
import NotificationService

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        Task { @MainActor in
            await NotificationManager.shared.checkAuthorizationStatus()
        }
        
        return true
    }
}
