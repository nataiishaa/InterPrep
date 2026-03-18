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
        print("🔍 DEBUG Upload: uploading file '\(file.name)' (\(fileData.count) bytes)")
        
        let result = await networkService.uploadFile(
            fileContent: fileData,
            filename: file.name,
            parentId: nil,
            name: file.name
        )
        
        switch result {
        case .success(let response):
            print("🔍 DEBUG Upload: success, materialID: '\(response.materialID)'")
            
            if !response.materialID.isEmpty {
                print("🔍 DEBUG Parse: calling parseResume with materialID: '\(response.materialID)'")
                let parseResult = await networkService.parseResume(materialId: response.materialID)
                
                switch parseResult {
                case .success(let parseResponse):
                    print("🔍 DEBUG Parse: success")
                    print("   - sessionId: '\(parseResponse.sessionID)'")
                    print("   - status: '\(parseResponse.status)'")
                    print("   - hasDraft: \(parseResponse.hasDraft)")
                    
                    if parseResponse.hasDraft {
                        let draft = parseResponse.draft
                        print("   - draft.targetRoles: \(draft.targetRoles)")
                        print("   - draft.areas: \(draft.areas.map { $0.name })")
                        print("   - draft.skillsTop: \(draft.skillsTop)")
                        print("   - draft.workFormat: \(draft.workFormat)")
                        print("   - draft.hasExperienceLevel: \(draft.hasExperienceLevel)")
                        print("   - draft.hasSalaryMin: \(draft.hasSalaryMin)")
                        
                        // Конвертируем draft в User_ResumeProfile и сохраняем
                        print("🔍 DEBUG: Converting draft to User_ResumeProfile and saving...")
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
                        
                        // Получаем userId из текущего профиля
                        let getMeResult = await networkService.getMe()
                        if case .success(let meResponse) = getMeResult {
                            let userId = meResponse.user.id
                            print("   - Saving to User_ResumeProfile for userId: \(userId)")
                            
                            let updateResult = await networkService.updateUser_ResumeProfile(
                                userId: userId,
                                profile: userProfile
                            )
                            
                            switch updateResult {
                            case .success:
                                print("   ✅ Profile saved successfully!")
                            case .failure(let err):
                                print("   ❌ Failed to save profile: \(err)")
                            }
                            
                            // Проверяем обновился ли флаг resumeUploaded в UserProfile
                            print("🔍 DEBUG: Checking UserProfile.resumeUploaded flag...")
                            let meCheckResult = await networkService.getMe()
                            switch meCheckResult {
                            case .success(let meResponse):
                                print("   - UserProfile.resumeUploaded = \(meResponse.user.resumeUploaded)")
                                print("   - UserProfile.id = \(meResponse.user.id)")
                            case .failure(let err):
                                print("   - GetMe check failed: \(err)")
                            }
                        } else {
                            print("   ❌ Failed to get current user ID")
                        }
                        
                        // После сохранения проверяем что данные действительно сохранились
                        print("🔍 DEBUG: Checking if profile was saved correctly...")
                        let profileCheckResult = await networkService.getUser_ResumeProfile()
                        switch profileCheckResult {
                        case .success(let profileResponse):
                            print("   - Profile check: hasProfile = \(profileResponse.hasProfile)")
                            print("   - Profile check: status = \(profileResponse.status)")
                            print("   - Profile check: sourceMaterialID = '\(profileResponse.sourceMaterialID)'")
                            if profileResponse.hasProfile {
                                print("   - Profile check: targetRoles = \(profileResponse.profile.targetRoles)")
                            }
                        case .failure(let err):
                            print("   - Profile check failed: \(err)")
                        }
                    }
                    print("   - questions count: \(parseResponse.questions.count)")
                case .failure(let error):
                    print("🔍 DEBUG Parse: error - \(error)")
                }
            }
            return
        case .failure(let error):
            print("🔍 DEBUG Upload: error - \(error)")
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
