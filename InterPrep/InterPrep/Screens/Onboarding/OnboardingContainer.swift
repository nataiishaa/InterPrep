import ArchitectureCore
import SwiftUI

public struct OnboardingContainer: View {
    @State private var store: OnboardingStore

    let onComplete: () -> Void
    let onRegister: () -> Void

    public init(
        store: OnboardingStore,
        onComplete: @escaping () -> Void,
        onRegister: @escaping () -> Void
    ) {
        self.store = store
        self.onComplete = onComplete
        self.onRegister = onRegister
    }

    public var body: some View {
        OnboardingView(model: makeModel())
            .onChange(of: store.state.isCompleted) { _, isCompleted in
                if isCompleted {
                    if store.state.shouldOpenRegistration {
                        onRegister()
                    } else {
                        onComplete()
                    }
                }
            }
    }

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
                store.send(.registerTapped)
            }
        )
    }

    private func mapPage(_ page: OnboardingState.OnboardingPage) -> OnboardingView.Model.PageModel {
        .init(
            id: page.id,
            imageName: page.imageName,
            title: page.title,
            description: page.description
        )
    }
}

#Preview {
    OnboardingContainer(
        store: Store(
            state: OnboardingState(),
            effectHandler: OnboardingEffectHandler(
                storageService: OnboardingStorageService()
            )
        ),
        onComplete: {},
        onRegister: {}
    )
}
