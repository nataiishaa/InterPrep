//
//  DiscoveryContainer.swift
//  InterPrep
//
//  Discovery container
//

import SwiftUI
import ArchitectureCore

public struct DiscoveryContainer: View {
    public typealias DiscoveryStore = Store<DiscoveryState, DiscoveryEffectHandler>
    
    @StateObject private var store: DiscoveryStore
    @State private var selectedVacancy: DiscoveryState.Vacancy?
    
    public init(store: @autoclosure @escaping () -> DiscoveryStore) {
        _store = StateObject(wrappedValue: store())
    }
    
    public var body: some View {
        DiscoveryView(model: makeModel())
            .task {
                store.send(.onAppear)
            }
            .sheet(item: $selectedVacancy) { vacancy in
                if let urlString = vacancy.url, let url = URL(string: urlString) {
                    NavigationStack {
                        VacancyWebView(url: url, title: vacancy.title)
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
                store.send(.uploadResumeTapped)
            },
            onVacancyTap: { vacancy in
                selectedVacancy = vacancy
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
