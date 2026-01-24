//
//  ResumeUploadEffectHandler.swift
//  InterPrep
//
//  Resume upload effect handler
//

import Foundation
import UniformTypeIdentifiers
import ArchitectureCore

public actor ResumeUploadEffectHandler: EffectHandler {
    public typealias S = ResumeUploadState
    
    private let fileService: FileUploadService
    private var uploadTask: Task<Void, Never>?
    
    public init(fileService: FileUploadService) {
        self.fileService = fileService
    }
    
    public func handle(effect: S.Effect) async -> S.Feedback? {
        switch effect {
        case let .validateFile(url):
            do {
                let file = try await fileService.validateFile(url)
                return .fileValidated(file)
            } catch {
                return .fileValidationFailed(error.localizedDescription)
            }
            
        case let .uploadFile(file):
            uploadTask?.cancel()
            uploadTask = Task {
                do {
                    // Имитируем загрузку с прогрессом
                    for progress in stride(from: 0.0, through: 1.0, by: 0.1) {
                        try Task.checkCancellation()
                        try await Task.sleep(nanoseconds: 300_000_000) // 0.3s
                        await sendFeedback(.uploadProgress(progress))
                    }
                    
                    try await fileService.uploadFile(file)
                    await sendFeedback(.uploadCompleted)
                    
                    // Ждем 1 секунду перед переходом
                    try await Task.sleep(nanoseconds: 1_000_000_000)
                    // TODO: Navigate to main
                    
                } catch is CancellationError {
                    await sendFeedback(.uploadFailed("Загрузка отменена"))
                } catch {
                    await sendFeedback(.uploadFailed(error.localizedDescription))
                }
            }
            return nil
            
        case .cancelUpload:
            uploadTask?.cancel()
            uploadTask = nil
            return nil
            
        case .navigateBack,
             .navigateToMain:
            // Navigation handled by coordinator
            return nil
        }
    }
    
    private func sendFeedback(_ feedback: S.Feedback) async {
        // В реальном приложении здесь будет отправка через Store
        // Пока просто заглушка
    }
}

// MARK: - File Upload Service

public protocol FileUploadService: Actor {
    func validateFile(_ url: URL) async throws -> ResumeUploadState.SelectedFile
    func uploadFile(_ file: ResumeUploadState.SelectedFile) async throws
}

// MARK: - Mock Service

public final actor FileUploadServiceMock: FileUploadService {
    public init() {}
    
    public func validateFile(_ url: URL) async throws -> ResumeUploadState.SelectedFile {
        // Имитируем задержку валидации
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5s
        
        // Получаем информацию о файле
        let resources = try url.resourceValues(forKeys: [.fileSizeKey, .nameKey])
        let fileName = resources.name ?? "resume.pdf"
        let fileSize = Int64(resources.fileSize ?? 0)
        
        // Определяем тип файла
        let fileExtension = url.pathExtension.lowercased()
        let fileType: ResumeUploadState.SelectedFile.FileType
        
        switch fileExtension {
        case "pdf":
            fileType = .pdf
        case "doc":
            fileType = .doc
        case "docx":
            fileType = .docx
        case "txt":
            fileType = .txt
        default:
            throw FileUploadError.unsupportedFormat
        }
        
        // Проверяем размер (макс 10 МБ)
        let maxSize: Int64 = 10 * 1024 * 1024 // 10 MB
        guard fileSize <= maxSize else {
            throw FileUploadError.fileTooLarge
        }
        
        return ResumeUploadState.SelectedFile(
            name: fileName,
            size: fileSize,
            url: url,
            type: fileType
        )
    }
    
    public func uploadFile(_ file: ResumeUploadState.SelectedFile) async throws {
        // Имитируем загрузку на сервер
        try await Task.sleep(nanoseconds: 3_000_000_000) // 3s
        
        // В реальном приложении здесь будет:
        // - Чтение файла
        // - Отправка на сервер
        // - Обработка ответа
    }
}

// MARK: - Errors

enum FileUploadError: LocalizedError {
    case unsupportedFormat
    case fileTooLarge
    case uploadFailed
    
    var errorDescription: String? {
        switch self {
        case .unsupportedFormat:
            return "Неподдерживаемый формат файла. Используйте PDF, DOC, DOCX или TXT"
        case .fileTooLarge:
            return "Файл слишком большой. Максимальный размер: 10 МБ"
        case .uploadFailed:
            return "Не удалось загрузить файл. Попробуйте еще раз"
        }
    }
}
