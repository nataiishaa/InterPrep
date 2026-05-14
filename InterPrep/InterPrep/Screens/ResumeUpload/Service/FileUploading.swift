import CacheService
import DiscoveryModule
import Foundation
import NetworkMonitorService
import NetworkService
import UniformTypeIdentifiers

public protocol FileUploading: Actor {
    func validateFile(_ url: URL) async throws -> ResumeUploadState.SelectedFile
    func uploadFile(_ file: ResumeUploadState.SelectedFile) async throws -> ResumeSessionInfo
}

public final actor FileUploadService: FileUploading {
    private let networkService: NetworkServiceV2
    private let resumeService: (any ResumeServicing)?

    public init(networkService: NetworkServiceV2 = .shared, resumeService: (any ResumeServicing)? = nil) {
        self.networkService = networkService
        self.resumeService = resumeService
    }

    public func validateFile(_ url: URL) async throws -> ResumeUploadState.SelectedFile {
        let filePath = url.standardizedFileURL.path
        guard FileManager.default.fileExists(atPath: filePath) else {
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
        case "docx":
            fileType = .docx
        case "rtf":
            fileType = .rtf
        case "txt":
            fileType = .txt
        case "doc":
            throw FileUploadError.legacyDocFormat
        default:
            throw FileUploadError.unsupportedFormat
        }

        let maxSize: Int64 = 20 * 1024 * 1024
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

    // swiftlint:disable:next cyclomatic_complexity function_body_length
    public func uploadFile(_ file: ResumeUploadState.SelectedFile) async throws -> ResumeSessionInfo {
        guard FileManager.default.fileExists(atPath: file.url.standardizedFileURL.path) else {
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
            return ResumeSessionInfo(
                sessionId: parseResponse.sessionID,
                questions: [],
                status: parseResponse.status
            )

        case .failure(let error):
            if case .transportError(let transportError) = error as? NetworkError,
               "\(transportError)".contains("invalidUTF8") {
                let profileCheckResult = await networkService.getUser_ResumeProfile()
                switch profileCheckResult {
                case .success:
                    await resumeService?.invalidateCache()
                    return ResumeSessionInfo(sessionId: "", questions: [], status: "completed")
                case .failure:
                    await resumeService?.invalidateCache()
                    return ResumeSessionInfo(sessionId: "", questions: [], status: "completed")
                }
            }

            if let networkError = error as? NetworkError {
                if networkError.isConnectionError {
                    let vpnLikely = await MainActor.run { NetworkMonitor.shared.isConnected }
                    throw vpnLikely ? FileUploadError.vpnLikely : FileUploadError.networkUnavailable
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
    case legacyDocFormat
    case fileTooLarge
    case fileNotFound
    case networkUnavailable
    case vpnLikely
    case uploadFailed
    case serverError(String)

    var errorDescription: String? {
        switch self {
        case .unsupportedFormat:
            return "Неподдерживаемый формат файла. Используйте PDF, DOCX, RTF или TXT"
        case .legacyDocFormat:
            return "Формат .doc не поддерживается. Сохраните файл как .docx или .pdf"
        case .fileTooLarge:
            return "Файл слишком большой. Максимальный размер: 20 МБ"
        case .fileNotFound:
            return "Файл не найден. Попробуйте выбрать файл снова"
        case .networkUnavailable:
            return "Нет подключения к интернету"
        case .vpnLikely:
            return "Кажется, у вас включён VPN. Отключите его и попробуйте снова"
        case .uploadFailed:
            return "Не удалось загрузить файл. Попробуйте еще раз"
        case .serverError(let message):
            return message
        }
    }
}
