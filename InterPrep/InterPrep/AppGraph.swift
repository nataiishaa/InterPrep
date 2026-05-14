import ArchitectureCore
import AuthFeature
import CalendarFeature
import ChatFeature
import DiscoveryModule
import DocumentsFeature
import NetworkService
import OnboardingFeature
import ProfileFeature
import ResumeUploadFeature
import SwiftUI

@MainActor
final class AppGraph {

    private lazy var onboardingStorageService: OnboardingStorageServicing = OnboardingStorageService()
    private lazy var authService: AuthServicing = AuthService()
    private lazy var resumeService: ResumeServicing = ResumeService()
    private lazy var vacancyService: VacancyService = VacancyService()
    private lazy var fileUploadService: FileUploading = {
        FileUploadService(resumeService: self.resumeService)
    }()
    private lazy var documentService: DocumentServicing = DocumentService()
    private lazy var chatService: ChatServicing = ChatService()
    private lazy var calendarService: CalendarServicing = CalendarService()

    func shouldShowOnboarding() -> Bool {
        return !onboardingStorageService.isOnboardingCompleted()
    }

    func makeOnboardingContainer(
        onComplete: @escaping () -> Void,
        onRegister: @escaping () -> Void
    ) -> some View {
        let effectHandler = OnboardingEffectHandler(
            storageService: onboardingStorageService
        )

        let store = Store(
            state: OnboardingState(),
            effectHandler: effectHandler
        )

        return OnboardingContainer(store: store, onComplete: onComplete, onRegister: onRegister)
    }

    func makeAuthContainer(
        initialFlow: AuthState.AuthFlow = .login,
        onComplete: @escaping () -> Void
    ) -> some View {
        let effectHandler = AuthEffectHandler(
            authService: authService,
            fileUploadService: fileUploadService
        )

        let store = Store(
            state: AuthState(initialFlow: initialFlow),
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

    func makeDiscoveryStore() -> DiscoveryStore {
        let effectHandler = DiscoveryEffectHandler(
            resumeService: self.resumeService,
            vacancyService: self.vacancyService
        )
        return Store(
            state: DiscoveryState(),
            effectHandler: effectHandler
        )
    }

    func makeDiscoveryContainer(onNavigateToResumeUpload: (() -> Void)? = nil) -> some View {
        return DiscoveryContainer(
            store: self.makeDiscoveryStore(),
            onNavigateToResumeUpload: onNavigateToResumeUpload
        )
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

    func makeChatStore() -> ChatStore {
        let effectHandler = ChatEffectHandler(
            chatService: self.chatService,
            favoritesProvider: self.vacancyService
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

private struct AppProfileSessionService: ProfileSessionServicing {
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
            case .apiError(let apiError):
                message = apiError.userMessage
            case .unauthorized:
                message = "Неверный пароль"
            case .httpError(let code, _):
                message = code == 401 ? "Неверный пароль" : "Ошибка сервера. Попробуйте позже."
            case .timeout(let vpnLikely):
                message = vpnLikely
                    ? "Не удалось подключиться к серверу. Возможно, включён VPN — попробуйте отключить его"
                    : "Нет интернета. Проверьте подключение и попробуйте снова"
            case .transportError, .decodingFailed, .noData, .invalidURL, .encodingFailed, .unknown:
                message = (error as? LocalizedError)?.errorDescription ?? "Ошибка сети. Проверьте подключение."
            }
            return .failure(ProfileSessionError(message))
        }
    }
}
