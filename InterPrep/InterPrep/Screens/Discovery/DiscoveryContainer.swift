//
//  DiscoveryContainer.swift
//  InterPrep
//
//  Discovery container
//

import ArchitectureCore
import NetworkMonitorService
import SwiftUI

public struct DiscoveryContainer: View {
    @StateObject private var store: DiscoveryStore
    @ObservedObject private var networkMonitor = NetworkMonitor.shared
    @State private var selectedVacancy: DiscoveryState.Vacancy?
    @State private var showOfflineToast = false
    var onNavigateToResumeUpload: (() -> Void)?
    
    public init(store: @autoclosure @escaping () -> DiscoveryStore, onNavigateToResumeUpload: (() -> Void)? = nil) {
        _store = StateObject(wrappedValue: store())
        self.onNavigateToResumeUpload = onNavigateToResumeUpload
    }
    
    public var body: some View {
        DiscoveryView(model: makeModel())
            .overlay(alignment: .bottom) {
                if showOfflineToast {
                    Text("Нет интернета — откройте вакансию позже")
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(Color.black.opacity(0.8))
                        .cornerRadius(12)
                        .padding(.bottom, 80)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(.easeInOut(duration: 0.3), value: showOfflineToast)
            .task {
                store.send(.onAppear)
            }
            .onChange(of: networkMonitor.isConnected) { _, isConnected in
                if isConnected && store.state.isOfflineMode {
                    store.send(.retryTapped)
                }
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
            errorMessage: store.state.errorMessage,
            isOfflineMode: store.state.isOfflineMode,
            onFilterChanged: { filter in
                store.send(.filterChanged(filter))
            },
            onUploadResume: {
                onNavigateToResumeUpload?()
            },
            onVacancyTap: { vacancy in
                if networkMonitor.isConnected {
                    selectedVacancy = vacancy
                } else {
                    showOfflineToast = true
                    Task {
                        try? await Task.sleep(nanoseconds: 2_500_000_000)
                        showOfflineToast = false
                    }
                }
            },
            onToggleFavorite: { id in
                store.send(.toggleFavorite(id))
            },
            onSearchQueryChanged: { query in
                store.send(.searchQueryChanged(query))
            },
            onSearchSubmitted: {
                store.send(.searchSubmitted)
            },
            onRetry: {
                store.send(.retryTapped)
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
