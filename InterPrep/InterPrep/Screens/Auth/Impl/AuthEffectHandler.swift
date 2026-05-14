import AnalyticsService
import ArchitectureCore
import Foundation
import ResumeUploadFeature

public actor AuthEffectHandler: EffectHandler {
    public typealias StateType = AuthState

    private let authService: AuthServicing
    private let fileUploadService: (any FileUploading)?
    private var uploadTask: Task<Void, Never>?

    public init(authService: AuthServicing, fileUploadService: (any FileUploading)? = nil) {
        self.authService = authService
        self.fileUploadService = fileUploadService
    }

    // swiftlint:disable:next cyclomatic_complexity function_body_length
    public func handle(effect: StateType.Effect) async -> StateType.Feedback? {
        switch effect {
        case let .performLogin(email, password):
            await trackEvent(.loginStarted)
            do {
                try await authService.login(email: email, password: password)
                await trackEvent(.loginCompleted(method: "email"))
                return .loginSuccess
            } catch {
                let msg = userMessage(for: error)
                await trackEvent(.loginFailed(error: msg))
                return .loginFailed(msg)
            }

        case let .performRegistration(firstName, lastName, email, password):
            await trackEvent(.registrationStarted)
            do {
                try await authService.register(
                    firstName: firstName,
                    lastName: lastName,
                    email: email,
                    password: password
                )
                await trackEvent(.registrationCompleted)
                return .registrationSuccess
            } catch {
                let msg = userMessage(for: error)
                await trackEvent(.registrationFailed(error: msg))
                return .registrationFailed(msg)
            }

        case let .sendResetCode(email):
            do {
                try await authService.sendPasswordResetCode(email: email)
                return .resetCodeSent
            } catch {
                return .resetCodeFailed(userMessage(for: error))
            }

        case let .verifyOTP(email, code):
            do {
                try await authService.verifyOTP(email: email, code: code)
                return .otpVerified
            } catch {
                return .otpFailed(userMessage(for: error))
            }

        case .uploadResume:
            do {
                try await authService.uploadResume()
                return .resumeUploaded
            } catch {
                return .registrationFailed(userMessage(for: error))
            }

        case let .changePassword(email, code, newPassword):
            do {
                try await authService.changePassword(email: email, code: code, newPassword: newPassword)
                return .passwordChanged
            } catch {
                return .loginFailed(userMessage(for: error))
            }

        case let .validateResumeFile(url):
            guard let fileService = fileUploadService else {
                return .resumeFileValidationFailed("Сервис загрузки недоступен")
            }
            do {
                let file = try await fileService.validateFile(url)
                return .resumeFileValidated(file)
            } catch {
                return .resumeFileValidationFailed(userMessage(for: error))
            }

        case let .uploadResumeFile(file):
            guard let fileService = fileUploadService else {
                return .resumeUploadFailed("Сервис загрузки недоступен")
            }
            uploadTask?.cancel()

            do {
                let session = try await fileService.uploadFile(file)
                return .resumeUploadCompleted(session)
            } catch is CancellationError {
                return .resumeUploadFailed("Загрузка отменена")
            } catch {
                return .resumeUploadFailed(userMessage(for: error))
            }

        case .cancelResumeUpload:
            uploadTask?.cancel()
            uploadTask = nil
            return nil
        }
    }

    private func userMessage(for error: Error) -> String {
        if let auth = error as? AuthError {
            return auth.errorDescription ?? "Произошла ошибка"
        }
        if let localizable = error as? LocalizedError, let desc = localizable.errorDescription {
            return desc
        }
        return "Произошла ошибка. Попробуйте позже"
    }

    @MainActor
    private func trackEvent(_ event: AnalyticsEvent) {
        AnalyticsManager.shared.track(event)
    }
}
