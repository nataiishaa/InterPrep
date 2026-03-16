//
//  OnboardingView+Model.swift
//  InterPrep
//
//  Onboarding view model
//

import Foundation

extension OnboardingView {
    struct Model {
        let currentPage: Int
        let pages: [PageModel]
        let isLastPage: Bool
        let onNext: () -> Void
        let onPrevious: () -> Void
        let onPageChanged: (Int) -> Void
        let onSkip: () -> Void
        let onGetStarted: () -> Void
        let onRegister: () -> Void
        
        struct PageModel: Identifiable {
            let id: Int
            let imageName: String
            let title: String
            let description: String
        }
    }
}

#if DEBUG
extension OnboardingView.Model {
    static var fixture: Self {
        .init(
            currentPage: 0,
            pages: [
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
                    description: "Карьерный консунтант подскажет, что улучшить в навыках и куда расти дальше"
                )
            ],
            isLastPage: false,
            onNext: {},
            onPrevious: {},
            onPageChanged: { _ in },
            onSkip: {},
            onGetStarted: {},
            onRegister: {}
        )
    }
    
    static var lastPageFixture: Self {
        .init(
            currentPage: 2,
            pages: [
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
                    description: "Карьерный консунтант подскажет, что улучшить в навыках и куда расти дальше"
                )
            ],
            isLastPage: true,
            onNext: {},
            onPrevious: {},
            onPageChanged: { _ in },
            onSkip: {},
            onGetStarted: {},
            onRegister: {}
        )
    }
}
#endif
