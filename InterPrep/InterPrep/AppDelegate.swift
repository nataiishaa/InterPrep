import AnalyticsService
import NotificationService
import Security
import UIKit
import UserNotifications

class AppDelegate: NSObject, UIApplicationDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        if CommandLine.arguments.contains("--ui-testing") {
            resetStateForUITesting()
        }

        configureAnalytics()

        Task { @MainActor in
            await NotificationManager.shared.checkAuthorizationStatus()
        }

        AnalyticsManager.shared.track(.appLaunched)

        return true
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        AnalyticsManager.shared.track(.appBackgrounded)
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        AnalyticsManager.shared.track(.appForegrounded)

        Task { @MainActor in
            await NotificationManager.shared.checkAuthorizationStatus()
        }
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        Task { @MainActor in
            await NotificationManager.shared.setBadgeCount(0)
        }
    }

    private func resetStateForUITesting() {
        UserDefaults.standard.removeObject(forKey: "isOnboardingCompleted")
        UserDefaults.standard.removeObject(forKey: "com.interprep.access_token")
        UserDefaults.standard.removeObject(forKey: "com.interprep.refresh_token")

        let service = "com.interprep.app"
        for account in ["com.interprep.access_token", "com.interprep.refresh_token"] {
            let query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: service,
                kSecAttrAccount as String: account
            ]
            SecItemDelete(query as CFDictionary)
        }
    }

    private func configureAnalytics() {
        let appMetricaService = AppMetricaService()
        AnalyticsManager.shared.configure(
            service: appMetricaService,
            apiKey: Secrets.appMetricaAPIKey
        )

        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        AnalyticsManager.shared.setUserProperties(
            AnalyticsUserProperties(appVersion: appVersion)
        )
    }
}
