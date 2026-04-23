//
//  MainTabView.swift
//  InterPrep
//
//  Main container with tab bar navigation
//

import ArchitectureCore
import CalendarFeature
import ChatFeature
import DesignSystem
import DiscoveryModule
import DocumentsFeature
import NetworkMonitorService
import ProfileFeature
import SwiftUI

struct MainTabView: View {
    @State private var selectedTab: TabItem = .search
    @State private var showChatSheet: Bool = false
    @State private var showResumeUploadSheet: Bool = false
    @State private var chatStore: ChatStore?
    @StateObject private var discoveryStore: DiscoveryStore
    @StateObject private var networkMonitor = NetworkMonitor.shared
    @StateObject private var syncManager = OfflineSyncManager.shared
    private let appGraph: AppGraph
    private let onLogout: (() -> Void)?
    private let profileSessionService: (any ProfileSessionService)?
    
    init(appGraph: AppGraph, onLogout: (() -> Void)? = nil, profileSessionService: (any ProfileSessionService)? = nil) {
        self.appGraph = appGraph
        self.onLogout = onLogout
        self.profileSessionService = profileSessionService
        _discoveryStore = StateObject(wrappedValue: appGraph.makeDiscoveryStore())
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                if !networkMonitor.isConnected {
                    OfflineBanner(hasPendingSync: syncManager.hasPendingOperations)
                }
                
                Group {
                    switch selectedTab {
                    case .calendar:
                        appGraph.makeCalendarContainer()
                    case .documents:
                        appGraph.makeDocumentsContainer()
                    case .search:
                        DiscoveryContainer(store: discoveryStore, onNavigateToResumeUpload: {
                            showResumeUploadSheet = true
                        })
                    case .chat:
                        appGraph.makeDiscoveryContainer()
                    case .profile:
                        ProfileContainer(
                            sessionService: profileSessionService,
                            onLogoutComplete: onLogout,
                            onNavigateToResumeUpload: { showResumeUploadSheet = true }
                        )
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            
            TabBarView(selectedTab: $selectedTab)
        }
        .ignoresSafeArea(.keyboard)
        .onChange(of: selectedTab) { oldValue, newValue in
            if newValue == .chat {
                if chatStore == nil {
                    chatStore = appGraph.makeChatStore()
                }
                showChatSheet = true
                selectedTab = oldValue
            }
        }
        .sheet(isPresented: $showChatSheet) {
            if let store = chatStore {
                ChatContainer(store: store)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
        }
        .sheet(isPresented: $showResumeUploadSheet) {
            appGraph.makeResumeUploadContainer(
                onComplete: { 
                    showResumeUploadSheet = false
                    // Перезагружаем вакансии после успешной загрузки резюме
                    discoveryStore.send(.onAppear)
                },
                onCancel: { showResumeUploadSheet = false }
            )
        }
    }
}

#Preview {
    let appGraph = AppGraph()
    MainTabView(appGraph: appGraph)
}
