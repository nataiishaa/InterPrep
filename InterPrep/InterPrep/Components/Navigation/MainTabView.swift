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
    private let appGraph: AppGraph
    
    init(appGraph: AppGraph) {
        self.appGraph = appGraph
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch selectedTab {
                case .calendar:
                    CalendarContainer()
                case .documents:
                    appGraph.makeDocumentsContainer()
                case .search:
                    appGraph.makeDiscoveryContainer()
                case .chat:
                    appGraph.makeDiscoveryContainer()
                case .profile:
                    ProfileContainer()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            TabBarView(selectedTab: $selectedTab)
        }
        .ignoresSafeArea(.keyboard)
        .onChange(of: selectedTab) { oldValue, newValue in
            if newValue == .chat {
                showChatSheet = true
                selectedTab = oldValue
            }
        }
        .sheet(isPresented: $showChatSheet) {
            appGraph.makeChatContainer()
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }
}

// MARK: - Preview

#Preview {
    let appGraph = AppGraph()
    MainTabView(appGraph: appGraph)
}
