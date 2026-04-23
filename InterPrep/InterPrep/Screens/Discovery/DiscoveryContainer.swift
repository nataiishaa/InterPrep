//
//  DiscoveryContainer.swift
//  InterPrep
//
//  Discovery container
//

import ArchitectureCore
import SwiftUI

public struct DiscoveryContainer: View {
    @StateObject private var store: DiscoveryStore
    @State private var selectedVacancy: DiscoveryState.Vacancy?
    var onNavigateToResumeUpload: (() -> Void)?
    
    public init(store: @autoclosure @escaping () -> DiscoveryStore, onNavigateToResumeUpload: (() -> Void)? = nil) {
        _store = StateObject(wrappedValue: store())
        self.onNavigateToResumeUpload = onNavigateToResumeUpload
    }
    
    public var body: some View {
        DiscoveryView(model: makeModel())
            .task {
                store.send(.onAppear)
            }
            .sheet(item: $selectedVacancy) { vacancy in
                if let urlString = vacancy.url, let url = URL(string: urlString) {
                    NavigationStack {
                        VacancyWebView(url: url, title: vacancy.title, vacancyId: vacancy.id)
                    }
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                            .foregroundColor(.orange)
                        Text("URL вакансии недоступен")
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .presentationDetents([.height(200)])
                }
            }
    }
    
    // MARK: - Make Model
    
    private func makeModel() -> DiscoveryView.Model {
        .init(
            selectedFilter: store.state.selectedFilter,
            hasResume: store.state.hasResume,
            isLoading: store.state.isLoading,
            vacancies: store.state.vacancies,
            searchQuery: store.state.searchQuery,
            onFilterChanged: { filter in
                store.send(.filterChanged(filter))
            },
            onUploadResume: {
                onNavigateToResumeUpload?()
            },
            onVacancyTap: { vacancy in
                selectedVacancy = vacancy
            },
            onToggleFavorite: { id in
                store.send(.toggleFavorite(id))
            },
            onSearchQueryChanged: { query in
                store.send(.searchQueryChanged(query))
            },
            onSearchSubmitted: {
                store.send(.searchSubmitted)
            }
        )
    }
}

// MARK: - Preview

#Preview {
    DiscoveryContainer(store: Store(
        state: DiscoveryState(),
        effectHandler: DiscoveryEffectHandler(
            resumeService: ResumeServiceMock(),
            vacancyService: VacancyServiceMock()
        )
    ))
}
