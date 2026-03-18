//
//  MainTabView.swift
//  InterPrep
//
//  Main container with tab bar navigation
//

import SwiftUI
import DesignSystem
import CalendarFeature
import DiscoveryModule
import ProfileFeature
import DocumentsFeature
import ChatFeature

struct MainTabView: View {
    @State private var selectedTab: TabItem = .search
    @State private var showChatSheet: Bool = false
    @State private var showResumeUploadSheet: Bool = false
    @State private var chatStore: ChatStore?
    private let appGraph: AppGraph
    private let onLogout: (() -> Void)?
    private let profileSessionService: (any ProfileSessionService)?
    
    init(appGraph: AppGraph, onLogout: (() -> Void)? = nil, profileSessionService: (any ProfileSessionService)? = nil) {
        self.appGraph = appGraph
        self.onLogout = onLogout
        self.profileSessionService = profileSessionService
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch selectedTab {
                case .calendar:
                    appGraph.makeCalendarContainer()
                case .documents:
                    appGraph.makeDocumentsContainer()
                case .search:
                    appGraph.makeDiscoveryContainer()
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
