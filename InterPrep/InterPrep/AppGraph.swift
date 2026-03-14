//
//  AppGraph.swift
//  InterPrep
//
//  Main dependency injection graph
//

import SwiftUI
import ArchitectureCore
import NetworkService
import OnboardingFeature
import AuthFeature
import DiscoveryModule
import ResumeUploadFeature
import DocumentsFeature
import ChatFeature
import ProfileFeature
import CalendarFeature

@MainActor
final class AppGraph {
    
    // MARK: - Shared Services
    
    private lazy var onboardingStorageService: OnboardingStorageService = OnboardingStorageServiceImpl()
    private lazy var authService: AuthService = AuthServiceImpl()
    private lazy var resumeService: ResumeService = ResumeServiceImpl()
    private lazy var vacancyService: VacancyService = VacancyServiceImpl()
    private lazy var fileUploadService: FileUploadService = FileUploadServiceImpl()
    private lazy var documentService: DocumentServiceProtocol = DocumentServiceImpl()
    private lazy var chatService: ChatServiceProtocol = ChatServiceMock()
    private lazy var calendarService: CalendarServiceProtocol = CalendarServiceImpl()
    
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
    
    func makeMainContainer(onLogout: @escaping () -> Void) -> some View {
        MainTabView(
            appGraph: self,
            onLogout: onLogout,
            profileSessionService: AppProfileSessionService()
        )
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
    
    func makeCalendarContainer() -> some View {
        let effectHandler = CalendarEffectHandler(
            calendarService: self.calendarService
        )
        return CalendarContainer(store: Store(
            state: CalendarState(),
            effectHandler: effectHandler
        ))
    }
    
    func makeChatContainer() -> some View {
        makeChatContainer(store: makeChatStore())
    }
    
    /// Store чата — создаётся один раз и передаётся в sheet, чтобы состояние не сбрасывалось при перерисовке родителя.
    func makeChatStore() -> ChatStore {
        let effectHandler = ChatEffectHandler(
            chatService: self.chatService
        )
        return Store(
            state: ChatState(),
            effectHandler: effectHandler
        )
    }
    
    private func makeChatContainer(store: ChatStore) -> some View {
        ChatContainer(store: store)
    }
}

// MARK: - Profile session service (адаптер к NetworkServiceV2)

private struct AppProfileSessionService: ProfileSessionService {
    func clearTokens() async {
        await NetworkServiceV2.shared.clearTokens()
    }

    func deleteAccount(password: String) async -> Result<Void, ProfileSessionError> {
        let result = await NetworkServiceV2.shared.deleteAccount(password: password)
        switch result {
        case .success(let response):
            return response.deleted ? .success(()) : .failure(ProfileSessionError("Не удалось удалить аккаунт"))
        case .failure(let error):
            let message: String
            switch error {
            case .unauthorized:
                message = "Неверный пароль"
            case .httpError(let code, _):
                message = code == 401 ? "Неверный пароль" : "Ошибка сервера. Попробуйте позже."
            case .transportError, .decodingFailed, .noData, .invalidURL, .encodingFailed, .unknown:
                message = "Ошибка сети. Проверьте подключение."
            }
            return .failure(ProfileSessionError(message))
        }
    }
}
