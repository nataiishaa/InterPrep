import AppMetricaCore
import Foundation

public final class AppMetricaService: AnalyticsServiceProtocol, @unchecked Sendable {
    private var isConfigured = false
    private let lock = NSLock()

    public init() {}

    public func configure(apiKey: String) {
        lock.lock()
        defer { lock.unlock() }

        guard !isConfigured else { return }

        let configuration = AppMetricaConfiguration(apiKey: apiKey)
        configuration?.sessionTimeout = 300
        configuration?.handleFirstActivationAsUpdate = false
        configuration?.handleActivationAsSessionStart = true

        if let config = configuration {
            AppMetrica.activate(with: config)
            isConfigured = true
        }
    }

    public func setEnabled(_ enabled: Bool) {
        AppMetrica.setDataSendingEnabled(enabled)
    }

    public func track(_ event: AnalyticsEvent) {
        guard isConfigured else { return }

        let params = event.parameters.isEmpty ? nil : event.parameters
        AppMetrica.reportEvent(name: event.name, parameters: params)
    }

    public func setUserProperties(_ properties: AnalyticsUserProperties) {
        guard isConfigured else { return }

        let profile = MutableUserProfile()

        if let userId = properties.userId {
            profile.apply(ProfileAttribute.customString("user_id").withValue(userId))
        }

        if let email = properties.email {
            profile.apply(ProfileAttribute.customString("email").withValue(email))
        }

        if let hasResume = properties.hasResume {
            profile.apply(ProfileAttribute.customBool("has_resume").withValue(hasResume))
        }

        if let region = properties.region {
            profile.apply(ProfileAttribute.customString("region").withValue(region))
        }

        if let appVersion = properties.appVersion {
            profile.apply(ProfileAttribute.customString("app_version").withValue(appVersion))
        }

        AppMetrica.reportUserProfile(profile)
    }

    public func setUserId(_ userId: String?) {
        AppMetrica.userProfileID = userId
    }

    public func resetUser() {
        AppMetrica.userProfileID = nil
    }
}
