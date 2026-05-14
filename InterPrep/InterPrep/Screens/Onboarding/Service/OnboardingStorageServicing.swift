import Foundation

public protocol OnboardingStorageServicing {
    func markOnboardingCompleted()
    func isOnboardingCompleted() -> Bool
}

public final class OnboardingStorageService: OnboardingStorageServicing {
    private let key = "isOnboardingCompleted"

    public init() {}

    public func markOnboardingCompleted() {
        UserDefaults.standard.set(true, forKey: key)
    }

    public func isOnboardingCompleted() -> Bool {
        UserDefaults.standard.bool(forKey: key)
    }
}
