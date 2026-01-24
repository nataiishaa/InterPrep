//
//  OnboardingContainer.swift
//  InterPrep
//
//  Container for Onboarding screen
//

import SwiftUI
import ArchitectureCore

public struct OnboardingContainer: View {
    public typealias OnboardingStore = Store<OnboardingState, OnboardingEffectHandler>
    
    @StateObject private var store: OnboardingStore
    
    // Callback when onboarding is completed
    let onComplete: () -> Void
    
    public init(
        store: @autoclosure @escaping () -> OnboardingStore,
        onComplete: @escaping () -> Void
    ) {
        self._store = StateObject(wrappedValue: store())
        self.onComplete = onComplete
    }
    
    public var body: some View {
        OnboardingView(model: makeModel())
            .onChange(of: store.state.isCompleted) { _, isCompleted in
                if isCompleted {
                    onComplete()
                }
            }
    }
    
    // MARK: - Make Model
    
    private func makeModel() -> OnboardingView.Model {
        .init(
            currentPage: store.state.currentPage,
            pages: store.state.pages.map(mapPage),
            isLastPage: store.state.currentPage == store.state.pages.count - 1,
            onNext: {
                store.send(.nextPageTapped)
            },
            onPrevious: {
                store.send(.previousPageTapped)
            },
            onPageChanged: { page in
                store.send(.pageChanged(page))
            },
            onSkip: {
                store.send(.skipTapped)
            },
            onGetStarted: {
                store.send(.getStartedTapped)
            },
            onRegister: {
                // TODO: Navigate to registration
                store.send(.getStartedTapped)
            }
        )
    }
    
    // MARK: - Mappers
    
    private func mapPage(_ page: OnboardingState.OnboardingPage) -> OnboardingView.Model.PageModel {
        .init(
            id: page.id,
            imageName: page.imageName,
            title: page.title,
            description: page.description
        )
    }
}

// MARK: - Preview

#Preview {
    OnboardingContainer(
        store: Store(
            state: OnboardingState(),
            effectHandler: OnboardingEffectHandler(
                storageService: OnboardingStorageServiceImpl()
            )
        )
    ) {}
}
