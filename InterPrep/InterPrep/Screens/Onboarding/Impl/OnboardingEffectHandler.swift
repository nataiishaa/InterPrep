import ArchitectureCore
import Foundation

public actor OnboardingEffectHandler: EffectHandler {
    public typealias StateType = OnboardingState

    private let storageService: OnboardingStorageServicing

    public init(storageService: OnboardingStorageServicing) {
        self.storageService = storageService
    }

    public func handle(effect: StateType.Effect) async -> StateType.Feedback? {
        switch effect {
        case .completeOnboarding:
            storageService.markOnboardingCompleted()
            return .onboardingCompleted

        case .completeOnboardingWithRegistration:
            storageService.markOnboardingCompleted()
            return .onboardingCompletedWithRegistration

        case .logPageView:
            return nil
        }
    }
}
