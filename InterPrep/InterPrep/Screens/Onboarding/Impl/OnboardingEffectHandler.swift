//
//  OnboardingEffectHandler.swift
//  InterPrep
//
//  Effect handler for Onboarding screen
//

import ArchitectureCore
import Foundation

public actor OnboardingEffectHandler: EffectHandler {
    public typealias StateType = OnboardingState
    
    private let storageService: OnboardingStorageService
    
    public init(storageService: OnboardingStorageService) {
        self.storageService = storageService
    }
    
    public func handle(effect: StateType.Effect) async -> StateType.Feedback? {
        switch effect {
        case .completeOnboarding:
            storageService.markOnboardingCompleted()
            return .onboardingCompleted
            
        case .logPageView:
            return nil
        }
    }
}

public protocol OnboardingStorageService {
    func markOnboardingCompleted()
    func isOnboardingCompleted() -> Bool
}

public final class OnboardingStorageServiceImpl: OnboardingStorageService {
    private let key = "isOnboardingCompleted"
    
    public init() {}
    
    public func markOnboardingCompleted() {
        UserDefaults.standard.set(true, forKey: key)
    }
    
    public func isOnboardingCompleted() -> Bool {
        UserDefaults.standard.bool(forKey: key)
    }
}
