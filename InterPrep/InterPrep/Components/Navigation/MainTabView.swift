import ArchitectureCore
import AuthFeature
import CalendarFeature
import ChatFeature
import DesignSystem
import DiscoveryModule
import DocumentsFeature
import ProfileFeature
import ResumeUploadFeature
import SwiftUI

private enum ResumeUploadStep: Equatable {
    case upload
    case profileReview
}

struct MainTabView: View {
    @State private var selectedTab: TabItem = .search
    @State private var showChatSheet: Bool = false
    @State private var showResumeUploadSheet: Bool = false
    @State private var resumeUploadStep: ResumeUploadStep = .upload
    @State private var chatStore: ChatStore
    @State private var discoveryStore: DiscoveryStore
    private let appGraph: AppGraph
    private let onLogout: (() -> Void)?
    private let profileSessionService: (any ProfileSessionServicing)?

    init(appGraph: AppGraph, onLogout: (() -> Void)? = nil, profileSessionService: (any ProfileSessionServicing)? = nil) {
        self.appGraph = appGraph
        self.onLogout = onLogout
        self.profileSessionService = profileSessionService
        self.discoveryStore = appGraph.makeDiscoveryStore()
        self.chatStore = appGraph.makeChatStore()
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
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
                        EmptyView()
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

            TabBarView(selectedTab: $selectedTab, onInterceptTab: { tab in
                if tab == .chat {
                    showChatSheet = true
                    return true
                }
                return false
            })
        }
        .ignoresSafeArea(.keyboard)
        .fullScreenCover(isPresented: $showChatSheet) {
            ChatContainer(store: chatStore)
        }
        .sheet(isPresented: $showResumeUploadSheet, onDismiss: {
            resumeUploadStep = .upload
        }, content: {
            ResumeUploadFlowView(
                step: $resumeUploadStep,
                makeUploadContainer: {
                    appGraph.makeResumeUploadContainer(
                        onComplete: {
                            resumeUploadStep = .profileReview
                        },
                        onCancel: { showResumeUploadSheet = false }
                    )
                },
                onFinish: {
                    showResumeUploadSheet = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        discoveryStore.send(.onAppear)
                    }
                }
            )
        })
    }
}

#Preview {
    let appGraph = AppGraph()
    MainTabView(appGraph: appGraph)
}

private struct ResumeUploadFlowView<UploadContent: View>: View {
    @Binding var step: ResumeUploadStep
    let makeUploadContainer: () -> UploadContent
    let onFinish: () -> Void

    var body: some View {
        switch step {
        case .upload:
            makeUploadContainer()
        case .profileReview:
            AuthResumeProfileReviewView(
                onConfirm: { onFinish() },
                onBack: { onFinish() }
            )
        }
    }
}
