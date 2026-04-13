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
import DiscoveryModule

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
    private let resumeService: (any ResumeService)?
    
    public init(networkService: NetworkServiceV2 = .shared, resumeService: (any ResumeService)? = nil) {
        self.networkService = networkService
        self.resumeService = resumeService
    }
    
    public func validateFile(_ url: URL) async throws -> ResumeUploadState.SelectedFile {
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw FileUploadError.fileNotFound
        }
        
        let resources = try url.resourceValues(forKeys: [.fileSizeKey, .nameKey])
        let fileName = resources.name ?? url.lastPathComponent
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
        
        let fileData: Data
        do {
            fileData = try Data(contentsOf: file.url)
        } catch {
            throw FileUploadError.fileNotFound
        }
        
        let result = await networkService.uploadAndParseResume(
            fileContent: fileData,
            filename: file.name
        )
        
        switch result {
        case .success(let parseResponse):
            if parseResponse.hasDraft {
                let draft = parseResponse.draft
                var userProfile = User_ResumeProfile()
                userProfile.targetRoles = draft.targetRoles
                if draft.hasExperienceLevel {
                    userProfile.experienceLevel = draft.experienceLevel
                }
                userProfile.areas = draft.areas.map { area in
                    var userArea = User_Area()
                    userArea.id = area.id
                    userArea.name = area.name
                    return userArea
                }
                if draft.hasSalaryMin {
                    userProfile.salaryMin = draft.salaryMin
                }
                if draft.hasCurrency {
                    userProfile.currency = draft.currency
                }
                userProfile.workFormat = draft.workFormat
                userProfile.skillsTop = draft.skillsTop
                if draft.hasNotes {
                    userProfile.notes = draft.notes
                }
                
                let getMeResult = await networkService.getMe()
                if case .success(let meResponse) = getMeResult {
                    let userId = meResponse.user.id
                    
                    let updateResult = await networkService.updateUser_ResumeProfile(
                        userId: userId,
                        profile: userProfile
                    )
                    
                    switch updateResult {
                    case .success:
                        break
                    case .failure(let err):
                        throw FileUploadError.serverError("Не удалось сохранить профиль: \(err.localizedDescription)")
                    }
                } else {
                    throw FileUploadError.serverError("Не удалось получить ID пользователя")
                }
                
                await resumeService?.invalidateCache()
            }
            
            return
        case .failure(let error):
            if case .transportError(let transportError) = error as? NetworkError,
               "\(transportError)".contains("invalidUTF8") {
                let profileCheckResult = await networkService.getUser_ResumeProfile()
                switch profileCheckResult {
                case .success(let profileResponse):
                    if profileResponse.hasProfile {
                        await resumeService?.invalidateCache()
                        return
                    } else {
                        await resumeService?.invalidateCache()
                        return
                    }
                case .failure:
                    await resumeService?.invalidateCache()
                    return
                }
            }
            
            if let networkError = error as? NetworkError {
                if networkError.isConnectionError {
                    throw FileUploadError.networkUnavailable
                }
                if let api = networkError.asAPIError {
                    throw FileUploadError.serverError(api.userMessage)
                }
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
