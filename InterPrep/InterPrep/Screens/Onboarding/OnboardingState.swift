//
//  OnboardingState.swift
//  InterPrep
//
//  Onboarding screen state
//

import Foundation
import ArchitectureCore

public struct OnboardingState {
    public var currentPage: Int = 0
    public var pages: [OnboardingPage] = OnboardingPage.defaultPages
    public var isCompleted: Bool = false
    
    public init() {}
    
    public struct OnboardingPage: Identifiable, Equatable, Sendable {
        public let id: Int
        public let imageName: String
        public let title: String
        public let description: String
        
        public init(id: Int, imageName: String, title: String, description: String) {
            self.id = id
            self.imageName = imageName
            self.title = title
            self.description = description
        }
    }
}

extension OnboardingState.OnboardingPage {
    static let defaultPages: [OnboardingState.OnboardingPage] = [
        .init(
            id: 0,
            imageName: "video.circle.fill",
            title: "Ищите работу в пару кликов",
            description: "Не тратьте время на просмотр неинтересных для вас вакансий"
        ),
        .init(
            id: 1,
            imageName: "calendar.circle.fill",
            title: "Планируйте собеседования",
            description: "Календарь и материалы для подготовки. Все в одном приложении."
        ),
        .init(
            id: 2,
            imageName: "chart.line.uptrend.xyaxis.circle.fill",
            title: "Прокачивайте карьеру",
            description: "AI подскажет, что улучшить в навыках и куда расти дальше"
        )
    ]
}

extension OnboardingState: FeatureState {
    public enum Input: Sendable {
        case nextPageTapped
        case previousPageTapped
        case pageChanged(Int)
        case skipTapped
        case getStartedTapped
    }
    
    public enum Feedback: Sendable {
        case onboardingCompleted
    }
    
    public enum Effect: Sendable {
        case completeOnboarding
        case logPageView(Int)
    }
    
    @MainActor
    public static func reduce(
        state: inout Self,
        with message: Message<Input, Feedback>
    ) -> Effect? {
        switch message {
        case .input(.nextPageTapped):
            if state.currentPage < state.pages.count - 1 {
                state.currentPage += 1
                return .logPageView(state.currentPage)
            } else {
                return .completeOnboarding
            }
            
        case .input(.previousPageTapped):
            if state.currentPage > 0 {
                state.currentPage -= 1
                return .logPageView(state.currentPage)
            }
            
        case let .input(.pageChanged(page)):
            state.currentPage = page
            return .logPageView(page)
            
        case .input(.skipTapped), .input(.getStartedTapped):
            return .completeOnboarding
            
        case .feedback(.onboardingCompleted):
            state.isCompleted = true
        }
        
        return nil
    }
}
