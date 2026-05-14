import AnalyticsService
import ArchitectureCore
import CacheService
import DiscoveryModule
import Foundation
import NetworkMonitorService
import NetworkService
import UniformTypeIdentifiers

public actor ResumeUploadEffectHandler: EffectHandler {
    public typealias StateType = ResumeUploadState

    private let fileService: FileUploading
    private var uploadTask: Task<Void, Never>?

    public init(fileService: FileUploading) {
        self.fileService = fileService
    }

    public func handle(effect: StateType.Effect) async -> StateType.Feedback? {
        switch effect {
        case let .validateFile(url):
            do {
                let file = try await fileService.validateFile(url)
                return .fileValidated(file)
            } catch {
                return .fileValidationFailed(userMessage(for: error, fallback: "Не удалось проверить файл"))
            }

        case let .uploadFile(file):
            uploadTask?.cancel()
            await trackEvent(.resumeUploadStarted)

            do {
                let session = try await fileService.uploadFile(file)
                await trackEvent(.resumeUploadCompleted(fileSize: Int(file.size)))
                return .uploadCompleted(session)
            } catch is CancellationError {
                return .uploadFailed("Загрузка отменена")
            } catch {
                let msg = userMessage(for: error, fallback: "Не удалось загрузить резюме")
                await trackEvent(.resumeUploadFailed(error: msg))
                return .uploadFailed(msg)
            }

        case .cancelUpload:
            uploadTask?.cancel()
            uploadTask = nil
            return nil

        case .navigateBack,
             .navigateToMain:
            return nil
        }
    }

    private func userMessage(for error: Error, fallback: String) -> String {
        if let ne = error as? NetworkError {
            if ne.isConnectionError {
                return "Нет интернета. Проверьте подключение и попробуйте снова"
            }
            if let api = ne.asAPIError {
                return api.userMessage
            }
        }
        if let localizable = error as? LocalizedError, let desc = localizable.errorDescription {
            return desc
        }
        return fallback
    }

    @MainActor
    private func trackEvent(_ event: AnalyticsEvent) {
        AnalyticsManager.shared.track(event)
    }
}
