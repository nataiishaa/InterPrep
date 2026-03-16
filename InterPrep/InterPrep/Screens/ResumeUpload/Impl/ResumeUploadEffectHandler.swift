//
//  ResumeUploadEffectHandler.swift
//  InterPrep
//
//  Resume upload effect handler
//

import Foundation
import UniformTypeIdentifiers
import ArchitectureCore
import NetworkService

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
            
            do {
                try await fileService.uploadFile(file)
                
                return .uploadCompleted
            } catch is CancellationError {
                return .uploadFailed("Загрузка отменена")
            } catch {
                return .uploadFailed(error.localizedDescription)
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
    
}

public protocol FileUploadService: Actor {
    func validateFile(_ url: URL) async throws -> ResumeUploadState.SelectedFile
    func uploadFile(_ file: ResumeUploadState.SelectedFile) async throws
}

public final actor FileUploadServiceImpl: FileUploadService {
    private let networkService: NetworkServiceV2
    
    public init(networkService: NetworkServiceV2 = .shared) {
        self.networkService = networkService
    }
    
    public func validateFile(_ url: URL) async throws -> ResumeUploadState.SelectedFile {
        let resources = try url.resourceValues(forKeys: [.fileSizeKey, .nameKey])
        let fileName = resources.name ?? "resume.pdf"
        let fileSize = Int64(resources.fileSize ?? 0)
        
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
        
        let maxSize: Int64 = 10 * 1024 * 1024
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
        guard FileManager.default.fileExists(atPath: file.url.path) else {
            throw FileUploadError.fileNotFound
        }
        
        let fileData = try Data(contentsOf: file.url)
        let result = await networkService.uploadFile(
            fileContent: fileData,
            filename: file.name,
            parentId: nil,
            name: file.name
        )
        
        switch result {
        case .success(let response):
            if !response.materialID.isEmpty {
                _ = await networkService.parseResume(materialId: response.materialID)
            }
            return
        case .failure(let error):
            if (error as? NetworkError)?.isConnectionError == true {
                throw FileUploadError.networkUnavailable
            }
            if let api = (error as? NetworkError)?.asAPIError {
                throw FileUploadError.serverError(api.userMessage)
            }
            throw FileUploadError.uploadFailed
        }
    }
}

enum FileUploadError: LocalizedError {
    case unsupportedFormat
    case fileTooLarge
    case fileNotFound
    case networkUnavailable
    case uploadFailed
    case serverError(String)
    
    var errorDescription: String? {
        switch self {
        case .unsupportedFormat:
            return "Неподдерживаемый формат файла. Используйте PDF, DOC, DOCX или TXT"
        case .fileTooLarge:
            return "Файл слишком большой. Максимальный размер: 10 МБ"
        case .fileNotFound:
            return "Файл не найден. Попробуйте выбрать файл снова"
        case .networkUnavailable:
            return "Нет соединения с интернетом. Проверьте подключение и попробуйте снова"
        case .uploadFailed:
            return "Не удалось загрузить файл. Попробуйте еще раз"
        case .serverError(let message):
            return message
        }
    }
}
