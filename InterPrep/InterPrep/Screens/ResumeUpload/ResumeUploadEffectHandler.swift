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
                // Perform actual upload
                try await fileService.uploadFile(file)
                
                // Return success feedback
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
            // Navigation handled by coordinator
            return nil
        }
    }
    
}

// MARK: - File Upload Service

public protocol FileUploadService: Actor {
    func validateFile(_ url: URL) async throws -> ResumeUploadState.SelectedFile
    func uploadFile(_ file: ResumeUploadState.SelectedFile) async throws
}

// MARK: - Real Service

public final actor FileUploadServiceImpl: FileUploadService {
    private let networkService: NetworkServiceV2
    
    public init(networkService: NetworkServiceV2 = .shared) {
        self.networkService = networkService
    }
    
    public func validateFile(_ url: URL) async throws -> ResumeUploadState.SelectedFile {
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
        print("📤 Starting file upload: \(file.name)")
        
        guard FileManager.default.fileExists(atPath: file.url.path) else {
            print("❌ File not found at path: \(file.url.path)")
            throw FileUploadError.fileNotFound
        }
        
        let fileData = try Data(contentsOf: file.url)
        print("📦 File data loaded: \(fileData.count) bytes")
        
        let result = await networkService.uploadFile(
            fileContent: fileData,
            filename: file.name,
            parentId: nil,
            name: file.name
        )
        
        switch result {
        case .success(let response):
            print("✅ File uploaded successfully!")
            print("   Material ID: \(response.materialID)")
            print("   Name: \(response.name)")
            print("   Size: \(response.size)")
            return
        case .failure(let error):
            print("❌ Upload failed: \(error)")
            
            // Check for specific network errors
            if (error as? NetworkError)?.isConnectionError == true {
                throw FileUploadError.networkUnavailable
            }
            
            throw FileUploadError.uploadFailed
        }
    }
}

// MARK: - Errors

enum FileUploadError: LocalizedError {
    case unsupportedFormat
    case fileTooLarge
    case fileNotFound
    case networkUnavailable
    case uploadFailed
    
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
        }
    }
}
