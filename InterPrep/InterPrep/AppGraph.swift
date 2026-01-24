//
//  AppGraph.swift
//  InterPrep
//
//  Main dependency injection graph
//

import SwiftUI
import ArchitectureCore
import OnboardingFeature
import AuthFeature
import DiscoveryModule
import ResumeUploadFeature
import DocumentsFeature
import ChatFeature

@MainActor
final class AppGraph {
    
    // MARK: - Shared Services
    
    private lazy var onboardingStorageService: OnboardingStorageService = OnboardingStorageServiceImpl()
    private lazy var authService: AuthService = AuthServiceMock()
    private lazy var resumeService: ResumeService = ResumeServiceMock()
    private lazy var vacancyService: VacancyService = VacancyServiceMock()
    private lazy var fileUploadService: FileUploadService = FileUploadServiceMock()
    private lazy var documentService: DocumentServiceProtocol = DocumentServiceMock()
    private lazy var chatService: ChatServiceProtocol = ChatServiceMock()
    
    // MARK: - State
    
    func shouldShowOnboarding() -> Bool {
        return !onboardingStorageService.isOnboardingCompleted()
    }
    
    // MARK: - Screen Factories
    
    func makeOnboardingContainer(onComplete: @escaping () -> Void) -> some View {
        let effectHandler = OnboardingEffectHandler(
            storageService: onboardingStorageService
        )
        
        let store = Store(
            state: OnboardingState(),
            effectHandler: effectHandler
        )
        
        return OnboardingContainer(store: store, onComplete: onComplete)
    }
    
    func makeAuthContainer(onComplete: @escaping () -> Void) -> some View {
        let effectHandler = AuthEffectHandler(
            authService: authService
        )
        
        let store = Store(
            state: AuthState(),
            effectHandler: effectHandler
        )
        
        return AuthContainer(store: store, onAuthComplete: onComplete)
    }
    
    func makeMainContainer() -> some View {
        MainTabView(appGraph: self)
    }
    
    func makeDiscoveryContainer() -> some View {
        let effectHandler = DiscoveryEffectHandler(
            resumeService: self.resumeService,
            vacancyService: self.vacancyService
        )
        return DiscoveryContainer(store: Store(
            state: DiscoveryState(),
            effectHandler: effectHandler
        ))
    }
    
    func makeResumeUploadContainer(
        onComplete: @escaping () -> Void,
        onCancel: @escaping () -> Void
    ) -> some View {
        let effectHandler = ResumeUploadEffectHandler(
            fileService: self.fileUploadService
        )
        return ResumeUploadContainer(
            store: Store(
                state: ResumeUploadState(),
                effectHandler: effectHandler
            ),
            onComplete: onComplete,
            onCancel: onCancel
        )
    }
    
    func makeDocumentsContainer() -> some View {
        let effectHandler = DocumentsEffectHandler(
            documentService: self.documentService
        )
        return DocumentsContainer(store: Store(
            state: DocumentsState(),
            effectHandler: effectHandler
        ))
    }
    
    func makeChatContainer() -> some View {
        let effectHandler = ChatEffectHandler(
            chatService: self.chatService
        )
        return ChatContainer(store: Store(
            state: ChatState(),
            effectHandler: effectHandler
        ))
    }
}
