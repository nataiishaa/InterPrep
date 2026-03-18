import Foundation
import SwiftProtobuf
import GRPC
import NIOCore
import NIOHPACK

public final class NetworkServiceV2: ObservableObject {
    public static let shared = NetworkServiceV2()
    
    private let factory: URLRequestFactory
    private let networkService: AsyncNetworkService
    private let tokenStorage: TokenStorage
    private let grpcAuthClient: BackendGatewayGRPCClient?
    
    private init() {
        self.tokenStorage = TokenStorage()
        self.grpcAuthClient = try? BackendGatewayGRPCClient(host: "193.124.33.223", port: 9090)
        
        self.factory = URLRequestFactory(
            networkProvider: DefaultNetworkProvider(
                scheme: "http",
                host: "193.124.33.223",
                port: 9090
            )
        )
        
        let sessionConfiguration = URLSessionConfiguration.default
        sessionConfiguration.timeoutIntervalForRequest = 60
        sessionConfiguration.timeoutIntervalForResource = 300
        sessionConfiguration.waitsForConnectivity = true
        sessionConfiguration.requestCachePolicy = .reloadIgnoringLocalCacheData
        
        let session = URLSession(configuration: sessionConfiguration)
        
        let tokenProvider = DefaultTokenProvider(tokenStorage: tokenStorage)
        self.networkService = AsyncNetworkService(
            session: session,
            tokenProvider: tokenProvider,
            responseObservers: [LoggingObserver()]
        )
    }
    
    // MARK: - Auth (gRPC)
    
    public func register(firstName: String, lastName: String, email: String, password: String, deviceId: String? = nil) async -> Result<Auth_RegisterResponse, NetworkError> {
        var request = Auth_RegisterRequest()
        request.firstName = firstName
        request.lastName = lastName
        request.email = email
        request.password = password
        if let deviceId = deviceId {
            request.deviceID = deviceId
        }
        
        if let client = grpcAuthClient {
            do {
                let response = try await client.register(request: request)
                await tokenStorage.setTokens(
                    accessToken: response.accessToken,
                    refreshToken: response.refreshToken
                )
                return .success(response)
            } catch {
                if let api = apiErrorFromGRPC(error) { return .failure(.apiError(api)) }
                return .failure(.transportError(error))
            }
        }
        
        let result = await networkService.perform(factory.register(request))
        if case .success(let response) = result {
            await tokenStorage.setTokens(
                accessToken: response.accessToken,
                refreshToken: response.refreshToken
            )
        }
        return result
    }
    
    public func login(email: String, password: String, deviceId: String? = nil) async -> Result<Auth_LoginResponse, NetworkError> {
        var request = Auth_LoginRequest()
        request.email = email
        request.password = password
        if let deviceId = deviceId {
            request.deviceID = deviceId
        }
        
        if let client = grpcAuthClient {
            do {
                let response = try await client.login(request: request)
                await tokenStorage.setTokens(
                    accessToken: response.accessToken,
                    refreshToken: response.refreshToken
                )
                return .success(response)
            } catch {
                if let api = apiErrorFromGRPC(error) { return .failure(.apiError(api)) }
                return .failure(.transportError(error))
            }
        }
        
        let result = await networkService.perform(factory.login(request))
        if case .success(let response) = result {
            await tokenStorage.setTokens(
                accessToken: response.accessToken,
                refreshToken: response.refreshToken
            )
        }
        return result
    }
    
    public func refresh(refreshToken: String, deviceId: String? = nil) async -> Result<Auth_RefreshResponse, NetworkError> {
        var request = Auth_RefreshRequest()
        request.refreshToken = refreshToken
        if let deviceId = deviceId {
            request.deviceID = deviceId
        }
        
        let result = await networkService.perform(factory.refresh(request))
        
        if case .success(let response) = result {
            await tokenStorage.setTokens(
                accessToken: response.accessToken,
                refreshToken: refreshToken
            )
        }
        
        return result
    }
    
    public func checkPasswordResetEmail(email: String) async -> Result<Auth_PasswordResetCheckEmailResponse, NetworkError> {
        var request = Auth_PasswordResetCheckEmailRequest()
        request.email = email
        return await networkService.perform(factory.checkPasswordResetEmail(request))
    }
    
    public func sendPasswordResetCode(email: String) async -> Result<Auth_PasswordResetSendCodeResponse, NetworkError> {
        var request = Auth_PasswordResetSendCodeRequest()
        request.email = email
        
        if let client = grpcAuthClient {
            do {
                let response = try await client.sendPasswordResetCode(request: request)
                return .success(response)
            } catch {
                if let api = apiErrorFromGRPC(error) { return .failure(.apiError(api)) }
                return .failure(.transportError(error))
            }
        }
        
        return await networkService.perform(factory.sendPasswordResetCode(request))
    }
    
    public func verifyPasswordReset(email: String, code: String, password: String) async -> Result<Auth_PasswordResetVerifyResponse, NetworkError> {
        var request = Auth_PasswordResetVerifyRequest()
        request.email = email
        request.code = code
        request.password = password
        
        if let client = grpcAuthClient {
            do {
                let response = try await client.verifyPasswordReset(request: request)
                return .success(response)
            } catch {
                if let api = apiErrorFromGRPC(error) { return .failure(.apiError(api)) }
                return .failure(.transportError(error))
            }
        }
        
        return await networkService.perform(factory.verifyPasswordReset(request))
    }
    
    // MARK: - User
    
    public func getMe() async -> Result<User_GetMeResponse, NetworkError> {
        if let client = grpcAuthClient {
            do {
                let token = await tokenStorage.getAccessToken()
                let response = try await client.getMe(accessToken: token)
                return .success(response)
            } catch {
                if let api = apiErrorFromGRPC(error) { return .failure(.apiError(api)) }
                return .failure(.transportError(error))
            }
        }
        let request = User_GetMeRequest()
        return await networkService.perform(factory.getMe(request))
    }
    
    public func getUser_ResumeProfile() async -> Result<User_GetResumeProfileResponse, NetworkError> {
        if let client = grpcAuthClient {
            do {
                let token = await tokenStorage.getAccessToken()
                let response = try await client.getResumeProfile(accessToken: token)
                return .success(response)
            } catch {
                if let api = apiErrorFromGRPC(error) { return .failure(.apiError(api)) }
                return .failure(.transportError(error))
            }
        }
        let request = User_GetResumeProfileRequest()
        return await networkService.perform(factory.getResumeProfile(request))
    }
    
    public func updateUser_ResumeProfile(userId: UInt32, profile: User_ResumeProfile) async -> Result<User_UpdateResumeProfileResponse, NetworkError> {
        var request = User_UpdateResumeProfileRequest()
        request.userID = userId
        request.profile = profile
        if let client = grpcAuthClient {
            do {
                let token = await tokenStorage.getAccessToken()
                let response = try await client.updateResumeProfile(request: request, accessToken: token)
                return .success(response)
            } catch {
                if let api = apiErrorFromGRPC(error) { return .failure(.apiError(api)) }
                return .failure(.transportError(error))
            }
        }
        return await networkService.perform(factory.updateResumeProfile(request))
    }
    
    public func updateUserProfile(firstName: String? = nil, lastName: String? = nil, email: String? = nil, notificationsEnabled: Bool? = nil) async -> Result<User_UpdateUserProfileResponse, NetworkError> {
        var request = User_UpdateUserProfileRequest()
        if let firstName = firstName {
            request.firstName = firstName
        }
        if let lastName = lastName {
            request.lastName = lastName
        }
        if let email = email {
            request.email = email
        }
        if let notificationsEnabled = notificationsEnabled {
            request.notificationsEnabled = notificationsEnabled
        }
        if let client = grpcAuthClient {
            do {
                let token = await tokenStorage.getAccessToken()
                let response = try await client.updateUserProfile(request: request, accessToken: token)
                return .success(response)
            } catch {
                if let api = apiErrorFromGRPC(error) { return .failure(.apiError(api)) }
                return .failure(.transportError(error))
            }
        }
        return await networkService.perform(factory.updateUserProfile(request))
    }
    
    public func deleteAccount(password: String) async -> Result<User_DeleteAccountResponse, NetworkError> {
        var request = User_DeleteAccountRequest()
        request.password = password
        if let client = grpcAuthClient {
            do {
                let token = await tokenStorage.getAccessToken()
                let response = try await client.deleteAccount(request: request, accessToken: token)
                if response.deleted {
                    await tokenStorage.clearTokens()
                }
                return .success(response)
            } catch {
                if let api = apiErrorFromGRPC(error) { return .failure(.apiError(api)) }
                return .failure(.transportError(error))
            }
        }
        let result = await networkService.perform(factory.deleteAccount(request))
        if case .success(let response) = result, response.deleted {
            await tokenStorage.clearTokens()
        }
        return result
    }
    
    public func getProfilePhoto() async -> Result<User_GetProfilePhotoResponse, NetworkError> {
        if let client = grpcAuthClient {
            do {
                let token = await tokenStorage.getAccessToken()
                let response = try await client.getProfilePhoto(accessToken: token)
                return .success(response)
            } catch {
                if let api = apiErrorFromGRPC(error) { return .failure(.apiError(api)) }
                return .failure(.transportError(error))
            }
        }
        return .failure(.unknown)
    }
    
    public func uploadProfilePhoto(imageData: Data, filename: String = "photo.jpg", mimeType: String = "image/jpeg") async -> Result<User_UploadProfilePhotoResponse, NetworkError> {
        guard let client = grpcAuthClient else {
            return .failure(.unknown)
        }
        var request = User_UploadProfilePhotoRequest()
        request.fileContent = imageData
        request.filename = filename
        request.mimeType = mimeType
        do {
            let token = await tokenStorage.getAccessToken()
            let response = try await client.uploadProfilePhoto(request: request, accessToken: token)
            return .success(response)
        } catch {
            if let api = apiErrorFromGRPC(error) { return .failure(.apiError(api)) }
            return .failure(.transportError(error))
        }
    }
    
    // MARK: - Jobs
    
    public func searchJobs(page: Int = 0, perPage: Int = 20) async -> Result<Jobs_SearchJobsResponse, NetworkError> {
        if let client = grpcAuthClient {
            do {
                let token = await tokenStorage.getAccessToken()
                let response = try await client.searchJobs(page: page, perPage: perPage, accessToken: token)
                return .success(response)
            } catch {
                if let api = apiErrorFromGRPC(error) { return .failure(.apiError(api)) }
                return .failure(.transportError(error))
            }
        }
        var request = Jobs_SearchJobsRequest()
        request.page = Int32(page)
        request.perPage = Int32(perPage)
        return await networkService.perform(factory.searchJobs(request))
    }
    
    public func addFavorite(vacancyId: String) async -> Result<Jobs_AddFavoriteResponse, NetworkError> {
        if let client = grpcAuthClient {
            do {
                let token = await tokenStorage.getAccessToken()
                let response = try await client.addFavorite(vacancyId: vacancyId, accessToken: token)
                return .success(response)
            } catch {
                if let api = apiErrorFromGRPC(error) { return .failure(.apiError(api)) }
                return .failure(.transportError(error))
            }
        }
        var request = Jobs_AddFavoriteRequest()
        request.vacancyID = vacancyId
        return await networkService.perform(factory.addFavorite(request))
    }
    
    public func removeFavorite(vacancyId: String) async -> Result<Jobs_RemoveFavoriteResponse, NetworkError> {
        if let client = grpcAuthClient {
            do {
                let token = await tokenStorage.getAccessToken()
                let response = try await client.removeFavorite(vacancyId: vacancyId, accessToken: token)
                return .success(response)
            } catch {
                if let api = apiErrorFromGRPC(error) { return .failure(.apiError(api)) }
                return .failure(.transportError(error))
            }
        }
        var request = Jobs_RemoveFavoriteRequest()
        request.vacancyID = vacancyId
        return await networkService.perform(factory.removeFavorite(request))
    }
    
    public func listFavorites() async -> Result<Jobs_ListFavoritesResponse, NetworkError> {
        if let client = grpcAuthClient {
            do {
                let token = await tokenStorage.getAccessToken()
                let response = try await client.listFavorites(accessToken: token)
                return .success(response)
            } catch {
                if let api = apiErrorFromGRPC(error) { return .failure(.apiError(api)) }
                return .failure(.transportError(error))
            }
        }
        let request = Jobs_ListFavoritesRequest()
        return await networkService.perform(factory.listFavorites(request))
    }
    
    // MARK: - Materials
    
    public func uploadFile(fileContent: Data, filename: String, parentId: UInt32? = nil, name: String? = nil) async -> Result<Materials_UploadFileResponse, NetworkError> {
        var request = Materials_UploadFileRequest()
        request.fileContent = fileContent
        request.filename = filename
        if let parentId = parentId {
            request.parentID = parentId
        }
        if let name = name {
            request.name = name
        }
        
        // Use gRPC client for file upload (more reliable for large files)
        if let client = grpcAuthClient {
            do {
                let token = await tokenStorage.getAccessToken()
                let response = try await client.uploadFile(request: request, accessToken: token)
                return .success(response)
            } catch {
                if let api = apiErrorFromGRPC(error) { return .failure(.apiError(api)) }
                return .failure(.transportError(error))
            }
        }
        
        // Fallback to URLSession (not recommended for gRPC backend)
        return await networkService.perform(factory.uploadFile(request))
    }
    
    public func downloadFile(materialId: String) async -> Result<Materials_DownloadFileResponse, NetworkError> {
        var request = Materials_DownloadFileRequest()
        request.materialID = materialId
        
        if let client = grpcAuthClient {
            do {
                let token = await tokenStorage.getAccessToken()
                let response = try await client.downloadFile(request: request, accessToken: token)
                return .success(response)
            } catch {
                if let api = apiErrorFromGRPC(error) { return .failure(.apiError(api)) }
                return .failure(.transportError(error))
            }
        }
        
        return await networkService.perform(factory.downloadFile(request))
    }
    
    public func listFolder(parentId: UInt32? = nil) async -> Result<Materials_ListFolderResponse, NetworkError> {
        var request = Materials_ListFolderRequest()
        if let parentId = parentId {
            request.parentID = parentId
        }
        
        if let client = grpcAuthClient {
            do {
                let token = await tokenStorage.getAccessToken()
                let response = try await client.listFolder(request: request, accessToken: token)
                return .success(response)
            } catch {
                if let api = apiErrorFromGRPC(error) { return .failure(.apiError(api)) }
                return .failure(.transportError(error))
            }
        }
        
        return await networkService.perform(factory.listFolder(request))
    }
    
    public func createFolder(name: String, parentId: UInt32? = nil) async -> Result<Materials_CreateFolderResponse, NetworkError> {
        var request = Materials_CreateFolderRequest()
        request.name = name
        if let parentId = parentId {
            request.parentID = parentId
        }
        if let client = grpcAuthClient {
            do {
                let token = await tokenStorage.getAccessToken()
                let response = try await client.createFolder(request: request, accessToken: token)
                return .success(response)
            } catch {
                if let api = apiErrorFromGRPC(error) { return .failure(.apiError(api)) }
                return .failure(.transportError(error))
            }
        }
        return await networkService.perform(factory.createFolder(request))
    }
    
    public func createLink(name: String, url: String, title: String? = nil, description: String? = nil, parentId: UInt32? = nil) async -> Result<Materials_CreateLinkResponse, NetworkError> {
        var request = Materials_CreateLinkRequest()
        request.name = name
        request.url = url
        if let title = title {
            request.title = title
        }
        if let description = description {
            request.description_p = description
        }
        if let parentId = parentId {
            request.parentID = parentId
        }
        return await networkService.perform(factory.createLink(request))
    }
    
    public func renameNode(nodeId: UInt32, newName: String) async -> Result<Materials_RenameNodeResponse, NetworkError> {
        var request = Materials_RenameNodeRequest()
        request.nodeID = nodeId
        request.newName = newName
        if let client = grpcAuthClient {
            do {
                let token = await tokenStorage.getAccessToken()
                let response = try await client.renameNode(request: request, accessToken: token)
                return .success(response)
            } catch {
                if let api = apiErrorFromGRPC(error) { return .failure(.apiError(api)) }
                return .failure(.transportError(error))
            }
        }
        return await networkService.perform(factory.renameNode(request))
    }
    
    public func deleteNode(nodeId: UInt32) async -> Result<Materials_DeleteNodeResponse, NetworkError> {
        var request = Materials_DeleteNodeRequest()
        request.nodeID = nodeId
        if let client = grpcAuthClient {
            do {
                let token = await tokenStorage.getAccessToken()
                let response = try await client.deleteNode(request: request, accessToken: token)
                return .success(response)
            } catch {
                if let api = apiErrorFromGRPC(error) { return .failure(.apiError(api)) }
                return .failure(.transportError(error))
            }
        }
        return await networkService.perform(factory.deleteNode(request))
    }
    
    // MARK: - Coach
    
    public func ask(conversationId: String? = nil, question: String, resumeProfile: User_ResumeProfile? = nil, contextChunks: [Coach_ContextChunk] = []) async -> Result<Coach_AskResponse, NetworkError> {
        var request = Coach_AskRequest()
        if let conversationId = conversationId {
            request.conversationID = conversationId
        }
        request.question = question
        if let resumeProfile = resumeProfile {
            request.resumeProfile = resumeProfile
        }
        request.contextChunks = contextChunks
        if let client = grpcAuthClient, let token = await tokenStorage.getAccessToken() {
            do {
                let response = try await client.ask(request: request, accessToken: token)
                return .success(response)
            } catch {
                if let api = apiErrorFromGRPC(error) { return .failure(.apiError(api)) }
                return .failure(.transportError(error))
            }
        }
        return await networkService.perform(factory.ask(request))
    }
    
    public func parseResume(materialId: String) async -> Result<Coach_ParseResumeResponse, NetworkError> {
        var request = Coach_ParseResumeRequest()
        request.materialID = materialId
        return await networkService.perform(factory.parseResume(request))
    }
    
    func answerResume(sessionId: String, answers: [Coach_QuestionAnswer]) async -> Result<Coach_AnswerResumeResponse, NetworkError> {
        var request = Coach_AnswerResumeRequest()
        request.sessionID = sessionId
        request.answers = answers
        return await networkService.perform(factory.answerResume(request))
    }
    
    public func getResumeSession(sessionId: String) async -> Result<Coach_GetResumeSessionResponse, NetworkError> {
        var request = Coach_GetResumeSessionRequest()
        request.sessionID = sessionId
        return await networkService.perform(factory.getResumeSession(request))
    }
    
    public func prepareForVacancy(vacancyId: String) async -> Result<Coach_PrepareForVacancyResponse, NetworkError> {
        var request = Coach_PrepareForVacancyRequest()
        request.vacancyID = vacancyId
        if let client = grpcAuthClient, let token = await tokenStorage.getAccessToken() {
            do {
                let response = try await client.prepareForVacancy(request: request, accessToken: token)
                return .success(response)
            } catch {
                if let api = apiErrorFromGRPC(error) { return .failure(.apiError(api)) }
                return .failure(.transportError(error))
            }
        }
        return await networkService.perform(factory.prepareForVacancy(request))
    }
    
    public func reviewResume() async -> Result<Coach_ReviewResumeResponse, NetworkError> {
        let request = Coach_ReviewResumeRequest()
        if let client = grpcAuthClient, let token = await tokenStorage.getAccessToken() {
            do {
                let response = try await client.reviewResume(request: request, accessToken: token)
                return .success(response)
            } catch {
                if let api = apiErrorFromGRPC(error) { return .failure(.apiError(api)) }
                return .failure(.transportError(error))
            }
        }
        return await networkService.perform(factory.reviewResume(request))
    }
    
    public func clearChatHistory(conversationId: String? = nil) async -> Result<Coach_ClearChatHistoryResponse, NetworkError> {
        var request = Coach_ClearChatHistoryRequest()
        if let conversationId = conversationId {
            request.conversationID = conversationId
        }
        if let client = grpcAuthClient, let token = await tokenStorage.getAccessToken() {
            do {
                let response = try await client.clearChatHistory(request: request, accessToken: token)
                return .success(response)
            } catch {
                if let api = apiErrorFromGRPC(error) { return .failure(.apiError(api)) }
                return .failure(.transportError(error))
            }
        }
        return await networkService.perform(factory.clearChatHistory(request))
    }
    
    public func getCoachChatHistory(pageSize: Int32 = 50, pageOffset: Int32 = 0) async -> Result<Coach_GetCoachChatHistoryResponse, NetworkError> {
        var request = Coach_GetCoachChatHistoryRequest()
        request.pageSize = pageSize
        request.pageOffset = pageOffset
        if let client = grpcAuthClient, let token = await tokenStorage.getAccessToken() {
            do {
                let response = try await client.getCoachChatHistory(request: request, accessToken: token)
                return .success(response)
            } catch {
                if let api = apiErrorFromGRPC(error) { return .failure(.apiError(api)) }
                return .failure(.transportError(error))
            }
        }
        return await networkService.perform(factory.getCoachChatHistory(request))
    }
    
    // MARK: - Calendar
    
    func createCalendar_Event(event: Calendar_Event) async -> Result<Calendar_CreateEventResponse, NetworkError> {
        var request = Calendar_CreateEventRequest()
        request.event = event
        return await networkService.perform(factory.createEvent(request))
    }
    
    public func createEvent(
        title: String,
        description: String,
        startTime: Date,
        endTime: Date,
        eventType: Calendar_EventType,
        location: String?,
        reminderEnabled: Bool,
        reminderMinutes: Int32
    ) async -> Result<Calendar_CreateEventResponse, NetworkError> {
        var event = Calendar_Event()
        event.title = title
        event.description_p = description
        event.eventType = eventType
        event.startTime = startTime.toProtoTimestamp()
        event.endTime = endTime.toProtoTimestamp()
        if let location = location {
            event.location = location
        }
        event.reminderEnabled = reminderEnabled
        event.reminderMinutes = reminderMinutes
        
        var request = Calendar_CreateEventRequest()
        request.event = event
        if let client = grpcAuthClient, let token = await tokenStorage.getAccessToken() {
            do {
                let response = try await client.createEvent(request: request, accessToken: token)
                return .success(response)
            } catch {
                if let api = apiErrorFromGRPC(error) { return .failure(.apiError(api)) }
                return .failure(.transportError(error))
            }
        }
        return await networkService.perform(factory.createEvent(request))
    }
    
    public func getCalendar_Event(id: String) async -> Result<Calendar_GetEventResponse, NetworkError> {
        var request = Calendar_GetEventRequest()
        request.id = id
        if let client = grpcAuthClient, let token = await tokenStorage.getAccessToken() {
            do {
                let response = try await client.getEvent(request: request, accessToken: token)
                return .success(response)
            } catch {
                if let api = apiErrorFromGRPC(error) { return .failure(.apiError(api)) }
                return .failure(.transportError(error))
            }
        }
        return await networkService.perform(factory.getEvent(request))
    }
    
    func updateCalendar_Event(id: String, patch: Calendar_EventPatch) async -> Result<Calendar_UpdateEventResponse, NetworkError> {
        var request = Calendar_UpdateEventRequest()
        request.id = id
        request.patch = patch
        return await networkService.perform(factory.updateEvent(request))
    }
    
    public func updateEvent(
        id: String,
        title: String?,
        description: String?,
        startTime: Date?,
        endTime: Date?,
        eventType: Calendar_EventType?,
        location: String?,
        reminderEnabled: Bool?,
        reminderMinutes: Int32?,
        completed: Bool? = nil
    ) async -> Result<Calendar_UpdateEventResponse, NetworkError> {
        var patch = Calendar_EventPatch()
        if let title = title {
            patch.title = title
        }
        if let description = description {
            patch.description_p = description
        }
        if let startTime = startTime {
            patch.startTime = startTime.toProtoTimestamp()
        }
        if let endTime = endTime {
            patch.endTime = endTime.toProtoTimestamp()
        }
        if let eventType = eventType {
            patch.eventType = eventType
        }
        if let location = location {
            patch.location = location
        }
        if let reminderEnabled = reminderEnabled {
            patch.reminderEnabled = reminderEnabled
        }
        if let reminderMinutes = reminderMinutes {
            patch.reminderMinutes = reminderMinutes
        }
        if let completed = completed {
            patch.completed = completed
        }
        
        var request = Calendar_UpdateEventRequest()
        request.id = id
        request.patch = patch
        if let client = grpcAuthClient, let token = await tokenStorage.getAccessToken() {
            do {
                let response = try await client.updateEvent(request: request, accessToken: token)
                return .success(response)
            } catch {
                if let api = apiErrorFromGRPC(error) { return .failure(.apiError(api)) }
                return .failure(.transportError(error))
            }
        }
        return await networkService.perform(factory.updateEvent(request))
    }
    
    public func deleteEvent(id: String) async -> Result<Calendar_DeleteEventResponse, NetworkError> {
        var request = Calendar_DeleteEventRequest()
        request.id = id
        if let client = grpcAuthClient, let token = await tokenStorage.getAccessToken() {
            do {
                let response = try await client.deleteEvent(request: request, accessToken: token)
                return .success(response)
            } catch {
                if let api = apiErrorFromGRPC(error) { return .failure(.apiError(api)) }
                return .failure(.transportError(error))
            }
        }
        return await networkService.perform(factory.deleteEvent(request))
    }
    
    func listCalendar_Events(fromTime: SwiftProtobuf.Google_Protobuf_Timestamp, toTime: SwiftProtobuf.Google_Protobuf_Timestamp, pageSize: Int32, pageToken: String = "", sort: Calendar_SortOrder = .sortStartAsc) async -> Result<Calendar_ListEventsResponse, NetworkError> {
        var request = Calendar_ListEventsRequest()
        request.fromTime = fromTime
        request.toTime = toTime
        request.pageSize = pageSize
        request.pageToken = pageToken
        request.sort = sort
        return await networkService.perform(factory.listEvents(request))
    }
    
    public func listEvents(
        fromTime: Date,
        toTime: Date,
        pageSize: Int32,
        pageToken: String? = nil,
        sort: Calendar_SortOrder = .sortStartAsc
    ) async -> Result<Calendar_ListEventsResponse, NetworkError> {
        var request = Calendar_ListEventsRequest()
        request.fromTime = fromTime.toProtoTimestamp()
        request.toTime = toTime.toProtoTimestamp()
        request.pageSize = pageSize
        if let pageToken = pageToken {
            request.pageToken = pageToken
        }
        request.sort = sort
        if let client = grpcAuthClient, let token = await tokenStorage.getAccessToken() {
            do {
                let response = try await client.listEvents(request: request, accessToken: token)
                return .success(response)
            } catch {
                if let api = apiErrorFromGRPC(error) { return .failure(.apiError(api)) }
                return .failure(.transportError(error))
            }
        }
        return await networkService.perform(factory.listEvents(request))
    }
    
    func listUpcoming(limit: Int32, fromTime: SwiftProtobuf.Google_Protobuf_Timestamp? = nil) async -> Result<Calendar_ListUpcomingResponse, NetworkError> {
        var request = Calendar_ListUpcomingRequest()
        request.limit = limit
        if let fromTime = fromTime {
            request.fromTime = fromTime
        }
        return await networkService.perform(factory.listUpcoming(request))
    }
    
    public func listUpcoming(limit: Int32, fromTime: Date) async -> Result<Calendar_ListUpcomingResponse, NetworkError> {
        var request = Calendar_ListUpcomingRequest()
        request.limit = limit
        request.fromTime = fromTime.toProtoTimestamp()
        if let client = grpcAuthClient, let token = await tokenStorage.getAccessToken() {
            do {
                let response = try await client.listUpcoming(request: request, accessToken: token)
                return .success(response)
            } catch {
                if let api = apiErrorFromGRPC(error) { return .failure(.apiError(api)) }
                return .failure(.transportError(error))
            }
        }
        return await networkService.perform(factory.listUpcoming(request))
    }
    
    // MARK: - Token Management
    
    public func clearTokens() async {
        await tokenStorage.clearTokens()
    }
    
    public func getAccessToken() async -> String? {
        await tokenStorage.getAccessToken()
    }
    
    public func getRefreshToken() async -> String? {
        await tokenStorage.getRefreshToken()
    }
}

// MARK: - gRPC Auth Client (in same file so always in target)

public final class BackendGatewayGRPCClient: Sendable {
    private let connection: ClientConnection
    private let group: EventLoopGroup
    private let client: Gateway_BackendGatewayClient

    public init(host: String = "193.124.33.223", port: Int = 9090) throws {
        self.group = PlatformSupport.makeEventLoopGroup(loopCount: 1)
        self.connection = ClientConnection.insecure(group: group)
            .connect(host: host, port: port)
        self.client = Gateway_BackendGatewayClient(channel: connection)
    }

    deinit {
        try? connection.close().wait()
    }

    public func register(request: Auth_RegisterRequest) async throws -> Auth_RegisterResponse {
        let call = client.register(request, callOptions: nil)
        return try await eventLoopFutureToAsync(call.response)
    }

    public func login(request: Auth_LoginRequest) async throws -> Auth_LoginResponse {
        let call = client.login(request, callOptions: nil)
        return try await eventLoopFutureToAsync(call.response)
    }

    public func sendPasswordResetCode(request: Auth_PasswordResetSendCodeRequest) async throws -> Auth_PasswordResetSendCodeResponse {
        let call = client.sendPasswordResetCode(request, callOptions: nil)
        return try await eventLoopFutureToAsync(call.response)
    }

    public func verifyPasswordReset(request: Auth_PasswordResetVerifyRequest) async throws -> Auth_PasswordResetVerifyResponse {
        let call = client.verifyPasswordReset(request, callOptions: nil)
        return try await eventLoopFutureToAsync(call.response)
    }

    public func getMe(accessToken: String?) async throws -> User_GetMeResponse {
        let request = User_GetMeRequest()
        let options = callOptions(with: accessToken)
        let call: UnaryCall<User_GetMeRequest, User_GetMeResponse> = connection.makeUnaryCall(
            path: "/gateway.BackendGateway/GetMe",
            request: request,
            callOptions: options,
            interceptors: []
        )
        return try await eventLoopFutureToAsync(call.response)
    }

    public func getResumeProfile(accessToken: String?) async throws -> User_GetResumeProfileResponse {
        let request = User_GetResumeProfileRequest()
        let options = callOptions(with: accessToken)
        let call = client.getResumeProfile(request, callOptions: options)
        return try await eventLoopFutureToAsync(call.response)
    }

    public func updateResumeProfile(request: User_UpdateResumeProfileRequest, accessToken: String?) async throws -> User_UpdateResumeProfileResponse {
        let options = callOptions(with: accessToken)
        let call: UnaryCall<User_UpdateResumeProfileRequest, User_UpdateResumeProfileResponse> = connection.makeUnaryCall(
            path: "/gateway.BackendGateway/UpdateResumeProfile",
            request: request,
            callOptions: options,
            interceptors: []
        )
        return try await eventLoopFutureToAsync(call.response)
    }

    public func updateUserProfile(request: User_UpdateUserProfileRequest, accessToken: String?) async throws -> User_UpdateUserProfileResponse {
        let options = callOptions(with: accessToken)
        let call: UnaryCall<User_UpdateUserProfileRequest, User_UpdateUserProfileResponse> = connection.makeUnaryCall(
            path: "/gateway.BackendGateway/UpdateUserProfile",
            request: request,
            callOptions: options,
            interceptors: []
        )
        return try await eventLoopFutureToAsync(call.response)
    }

    public func deleteAccount(request: User_DeleteAccountRequest, accessToken: String?) async throws -> User_DeleteAccountResponse {
        let options = callOptions(with: accessToken)
        let call: UnaryCall<User_DeleteAccountRequest, User_DeleteAccountResponse> = connection.makeUnaryCall(
            path: "/gateway.BackendGateway/DeleteAccount",
            request: request,
            callOptions: options,
            interceptors: []
        )
        return try await eventLoopFutureToAsync(call.response)
    }

    public func getProfilePhoto(accessToken: String?) async throws -> User_GetProfilePhotoResponse {
        let request = User_GetProfilePhotoRequest()
        let options = callOptions(with: accessToken)
        let call: UnaryCall<User_GetProfilePhotoRequest, User_GetProfilePhotoResponse> = connection.makeUnaryCall(
            path: "/gateway.BackendGateway/GetProfilePhoto",
            request: request,
            callOptions: options,
            interceptors: []
        )
        return try await eventLoopFutureToAsync(call.response)
    }

    public func uploadProfilePhoto(request: User_UploadProfilePhotoRequest, accessToken: String?) async throws -> User_UploadProfilePhotoResponse {
        let options = callOptions(with: accessToken)
        let call: UnaryCall<User_UploadProfilePhotoRequest, User_UploadProfilePhotoResponse> = connection.makeUnaryCall(
            path: "/gateway.BackendGateway/UploadProfilePhoto",
            request: request,
            callOptions: options,
            interceptors: []
        )
        return try await eventLoopFutureToAsync(call.response)
    }

    public func searchJobs(page: Int = 0, perPage: Int = 20, accessToken: String?) async throws -> Jobs_SearchJobsResponse {
        var request = Jobs_SearchJobsRequest()
        request.page = Int32(page)
        request.perPage = Int32(perPage)
        let options = callOptions(with: accessToken)
        let call = client.searchJobs(request, callOptions: options)
        return try await eventLoopFutureToAsync(call.response)
    }

    public func listFavorites(accessToken: String?) async throws -> Jobs_ListFavoritesResponse {
        let request = Jobs_ListFavoritesRequest()
        let options = callOptions(with: accessToken)
        let call = client.listFavorites(request, callOptions: options)
        return try await eventLoopFutureToAsync(call.response)
    }
    
    public func addFavorite(vacancyId: String, accessToken: String?) async throws -> Jobs_AddFavoriteResponse {
        var request = Jobs_AddFavoriteRequest()
        request.vacancyID = vacancyId
        let options = callOptions(with: accessToken)
        let call: UnaryCall<Jobs_AddFavoriteRequest, Jobs_AddFavoriteResponse> = connection.makeUnaryCall(
            path: "/gateway.BackendGateway/AddFavorite",
            request: request,
            callOptions: options,
            interceptors: []
        )
        return try await eventLoopFutureToAsync(call.response)
    }
    
    public func removeFavorite(vacancyId: String, accessToken: String?) async throws -> Jobs_RemoveFavoriteResponse {
        var request = Jobs_RemoveFavoriteRequest()
        request.vacancyID = vacancyId
        let options = callOptions(with: accessToken)
        let call: UnaryCall<Jobs_RemoveFavoriteRequest, Jobs_RemoveFavoriteResponse> = connection.makeUnaryCall(
            path: "/gateway.BackendGateway/RemoveFavorite",
            request: request,
            callOptions: options,
            interceptors: []
        )
        return try await eventLoopFutureToAsync(call.response)
    }
    
    // MARK: - Materials (using low-level gRPC API)
    
    public func uploadFile(request: Materials_UploadFileRequest, accessToken: String?) async throws -> Materials_UploadFileResponse {
        let options = callOptions(with: accessToken)
        let call: UnaryCall<Materials_UploadFileRequest, Materials_UploadFileResponse> = connection.makeUnaryCall(
            path: "/gateway.BackendGateway/UploadFile",
            request: request,
            callOptions: options,
            interceptors: []
        )
        return try await eventLoopFutureToAsync(call.response)
    }
    
    public func downloadFile(request: Materials_DownloadFileRequest, accessToken: String?) async throws -> Materials_DownloadFileResponse {
        let options = callOptions(with: accessToken)
        let call: UnaryCall<Materials_DownloadFileRequest, Materials_DownloadFileResponse> = connection.makeUnaryCall(
            path: "/gateway.BackendGateway/DownloadFile",
            request: request,
            callOptions: options,
            interceptors: []
        )
        return try await eventLoopFutureToAsync(call.response)
    }
    
    public func listFolder(request: Materials_ListFolderRequest, accessToken: String?) async throws -> Materials_ListFolderResponse {
        let options = callOptions(with: accessToken)
        let call: UnaryCall<Materials_ListFolderRequest, Materials_ListFolderResponse> = connection.makeUnaryCall(
            path: "/gateway.BackendGateway/ListFolder",
            request: request,
            callOptions: options,
            interceptors: []
        )
        return try await eventLoopFutureToAsync(call.response)
    }
    
    public func createFolder(request: Materials_CreateFolderRequest, accessToken: String?) async throws -> Materials_CreateFolderResponse {
        let options = callOptions(with: accessToken)
        let call: UnaryCall<Materials_CreateFolderRequest, Materials_CreateFolderResponse> = connection.makeUnaryCall(
            path: "/gateway.BackendGateway/CreateFolder",
            request: request,
            callOptions: options,
            interceptors: []
        )
        return try await eventLoopFutureToAsync(call.response)
    }
    
    public func renameNode(request: Materials_RenameNodeRequest, accessToken: String?) async throws -> Materials_RenameNodeResponse {
        let options = callOptions(with: accessToken)
        let call: UnaryCall<Materials_RenameNodeRequest, Materials_RenameNodeResponse> = connection.makeUnaryCall(
            path: "/gateway.BackendGateway/RenameNode",
            request: request,
            callOptions: options,
            interceptors: []
        )
        return try await eventLoopFutureToAsync(call.response)
    }
    
    public func deleteNode(request: Materials_DeleteNodeRequest, accessToken: String?) async throws -> Materials_DeleteNodeResponse {
        let options = callOptions(with: accessToken)
        let call: UnaryCall<Materials_DeleteNodeRequest, Materials_DeleteNodeResponse> = connection.makeUnaryCall(
            path: "/gateway.BackendGateway/DeleteNode",
            request: request,
            callOptions: options,
            interceptors: []
        )
        return try await eventLoopFutureToAsync(call.response)
    }
    
    // MARK: - Coach (gRPC HTTP/2; LLM — таймаут 120 с)
    
    public func ask(request: Coach_AskRequest, accessToken: String?) async throws -> Coach_AskResponse {
        let options = callOptionsForLLM(with: accessToken)
        let call: UnaryCall<Coach_AskRequest, Coach_AskResponse> = connection.makeUnaryCall(
            path: "/gateway.BackendGateway/Ask",
            request: request,
            callOptions: options,
            interceptors: []
        )
        return try await eventLoopFutureToAsync(call.response)
    }
    
    public func prepareForVacancy(request: Coach_PrepareForVacancyRequest, accessToken: String?) async throws -> Coach_PrepareForVacancyResponse {
        let options = callOptionsForLLM(with: accessToken)
        let call: UnaryCall<Coach_PrepareForVacancyRequest, Coach_PrepareForVacancyResponse> = connection.makeUnaryCall(
            path: "/gateway.BackendGateway/PrepareForVacancy",
            request: request,
            callOptions: options,
            interceptors: []
        )
        return try await eventLoopFutureToAsync(call.response)
    }
    
    public func reviewResume(request: Coach_ReviewResumeRequest, accessToken: String?) async throws -> Coach_ReviewResumeResponse {
        let options = callOptionsForLLM(with: accessToken)
        let call: UnaryCall<Coach_ReviewResumeRequest, Coach_ReviewResumeResponse> = connection.makeUnaryCall(
            path: "/gateway.BackendGateway/ReviewResume",
            request: request,
            callOptions: options,
            interceptors: []
        )
        return try await eventLoopFutureToAsync(call.response)
    }
    
    public func clearChatHistory(request: Coach_ClearChatHistoryRequest, accessToken: String?) async throws -> Coach_ClearChatHistoryResponse {
        let options = callOptions(with: accessToken)
        let call: UnaryCall<Coach_ClearChatHistoryRequest, Coach_ClearChatHistoryResponse> = connection.makeUnaryCall(
            path: "/gateway.BackendGateway/ClearChatHistory",
            request: request,
            callOptions: options,
            interceptors: []
        )
        return try await eventLoopFutureToAsync(call.response)
    }
    
    public func getCoachChatHistory(request: Coach_GetCoachChatHistoryRequest, accessToken: String?) async throws -> Coach_GetCoachChatHistoryResponse {
        let options = callOptions(with: accessToken)
        let call: UnaryCall<Coach_GetCoachChatHistoryRequest, Coach_GetCoachChatHistoryResponse> = connection.makeUnaryCall(
            path: "/gateway.BackendGateway/GetCoachChatHistory",
            request: request,
            callOptions: options,
            interceptors: []
        )
        return try await eventLoopFutureToAsync(call.response)
    }
    
    // MARK: - Calendar (gRPC HTTP/2, same as Materials)
    
    public func listEvents(request: Calendar_ListEventsRequest, accessToken: String?) async throws -> Calendar_ListEventsResponse {
        let options = callOptions(with: accessToken)
        let call: UnaryCall<Calendar_ListEventsRequest, Calendar_ListEventsResponse> = connection.makeUnaryCall(
            path: "/gateway.BackendGateway/ListEvents",
            request: request,
            callOptions: options,
            interceptors: []
        )
        return try await eventLoopFutureToAsync(call.response)
    }
    
    public func listUpcoming(request: Calendar_ListUpcomingRequest, accessToken: String?) async throws -> Calendar_ListUpcomingResponse {
        let options = callOptions(with: accessToken)
        let call: UnaryCall<Calendar_ListUpcomingRequest, Calendar_ListUpcomingResponse> = connection.makeUnaryCall(
            path: "/gateway.BackendGateway/ListUpcoming",
            request: request,
            callOptions: options,
            interceptors: []
        )
        return try await eventLoopFutureToAsync(call.response)
    }
    
    public func createEvent(request: Calendar_CreateEventRequest, accessToken: String?) async throws -> Calendar_CreateEventResponse {
        let options = callOptions(with: accessToken)
        let call: UnaryCall<Calendar_CreateEventRequest, Calendar_CreateEventResponse> = connection.makeUnaryCall(
            path: "/gateway.BackendGateway/CreateEvent",
            request: request,
            callOptions: options,
            interceptors: []
        )
        return try await eventLoopFutureToAsync(call.response)
    }
    
    public func getEvent(request: Calendar_GetEventRequest, accessToken: String?) async throws -> Calendar_GetEventResponse {
        let options = callOptions(with: accessToken)
        let call: UnaryCall<Calendar_GetEventRequest, Calendar_GetEventResponse> = connection.makeUnaryCall(
            path: "/gateway.BackendGateway/GetEvent",
            request: request,
            callOptions: options,
            interceptors: []
        )
        return try await eventLoopFutureToAsync(call.response)
    }
    
    public func updateEvent(request: Calendar_UpdateEventRequest, accessToken: String?) async throws -> Calendar_UpdateEventResponse {
        let options = callOptions(with: accessToken)
        let call: UnaryCall<Calendar_UpdateEventRequest, Calendar_UpdateEventResponse> = connection.makeUnaryCall(
            path: "/gateway.BackendGateway/UpdateEvent",
            request: request,
            callOptions: options,
            interceptors: []
        )
        return try await eventLoopFutureToAsync(call.response)
    }
    
    public func deleteEvent(request: Calendar_DeleteEventRequest, accessToken: String?) async throws -> Calendar_DeleteEventResponse {
        let options = callOptions(with: accessToken)
        let call: UnaryCall<Calendar_DeleteEventRequest, Calendar_DeleteEventResponse> = connection.makeUnaryCall(
            path: "/gateway.BackendGateway/DeleteEvent",
            request: request,
            callOptions: options,
            interceptors: []
        )
        return try await eventLoopFutureToAsync(call.response)
    }

    private func callOptions(with token: String?) -> CallOptions {
        var metadata = HPACKHeaders()
        if let token = token, !token.isEmpty {
            metadata.add(name: "authorization", value: "Bearer \(token)")
        }
        return CallOptions(customMetadata: metadata)
    }
    
    /// Таймаут 120 с для LLM-запросов (Ask и др.), как в гайде.
    private func callOptionsForLLM(with token: String?) -> CallOptions {
        var metadata = HPACKHeaders()
        if let token = token, !token.isEmpty {
            metadata.add(name: "authorization", value: "Bearer \(token)")
        }
        return CallOptions(
            customMetadata: metadata,
            timeLimit: .timeout(.seconds(120))
        )
    }
}

private func apiErrorFromGRPC(_ error: Error) -> APIError? {
    guard let status = error as? GRPCStatus else { return nil }
    let code: APIErrorCode
    switch status.code {
    case .unauthenticated: code = .unauthenticated
    case .invalidArgument: code = .invalidArgument
    case .notFound: code = .notFound
    case .alreadyExists: code = .alreadyExists
    case .permissionDenied: code = .permissionDenied
    case .resourceExhausted: code = .resourceExhausted
    case .failedPrecondition: code = .failedPrecondition
    case .internalError: code = .internalError
    default: code = .unknown
    }
    return APIError(code: code, serverMessage: status.message ?? "")
}

private func eventLoopFutureToAsync<T>(_ future: EventLoopFuture<T>) async throws -> T {
    try await withCheckedThrowingContinuation { continuation in
        future.whenComplete { result in
            switch result {
            case .success(let value):
                continuation.resume(returning: value)
            case .failure(let error):
                continuation.resume(throwing: error)
            }
        }
    }
}
