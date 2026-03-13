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
    /// gRPC клиент для Register/Login (сервер на :9090 говорит по gRPC/HTTP2).
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
        sessionConfiguration.timeoutIntervalForRequest = 30
        sessionConfiguration.timeoutIntervalForResource = 60
        sessionConfiguration.waitsForConnectivity = true
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
        return await networkService.perform(factory.sendPasswordResetCode(request))
    }
    
    public func verifyPasswordReset(email: String, code: String, password: String) async -> Result<Auth_PasswordResetVerifyResponse, NetworkError> {
        var request = Auth_PasswordResetVerifyRequest()
        request.email = email
        request.code = code
        request.password = password
        return await networkService.perform(factory.verifyPasswordReset(request))
    }
    
    // MARK: - User
    
    public func getMe() async -> Result<User_GetMeResponse, NetworkError> {
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
        return await networkService.perform(factory.updateUserProfile(request))
    }
    
    public func deleteAccount(password: String) async -> Result<User_DeleteAccountResponse, NetworkError> {
        var request = User_DeleteAccountRequest()
        request.password = password
        let result = await networkService.perform(factory.deleteAccount(request))
        
        if case .success(let response) = result, response.deleted {
            await tokenStorage.clearTokens()
        }
        
        return result
    }
    
    // MARK: - Jobs
    
    public func searchJobs(page: Int = 0, perPage: Int = 20) async -> Result<Jobs_SearchJobsResponse, NetworkError> {
        if let client = grpcAuthClient {
            do {
                let token = await tokenStorage.getAccessToken()
                let response = try await client.searchJobs(page: page, perPage: perPage, accessToken: token)
                return .success(response)
            } catch {
                return .failure(.transportError(error))
            }
        }
        var request = Jobs_SearchJobsRequest()
        request.page = Int32(page)
        request.perPage = Int32(perPage)
        return await networkService.perform(factory.searchJobs(request))
    }
    
    public func addFavorite(vacancyId: String) async -> Result<Jobs_AddFavoriteResponse, NetworkError> {
        var request = Jobs_AddFavoriteRequest()
        request.vacancyID = vacancyId
        return await networkService.perform(factory.addFavorite(request))
    }
    
    public func removeFavorite(vacancyId: String) async -> Result<Jobs_RemoveFavoriteResponse, NetworkError> {
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
        return await networkService.perform(factory.uploadFile(request))
    }
    
    public func downloadFile(materialId: String) async -> Result<Materials_DownloadFileResponse, NetworkError> {
        var request = Materials_DownloadFileRequest()
        request.materialID = materialId
        return await networkService.perform(factory.downloadFile(request))
    }
    
    public func listFolder(parentId: UInt32? = nil) async -> Result<Materials_ListFolderResponse, NetworkError> {
        var request = Materials_ListFolderRequest()
        if let parentId = parentId {
            request.parentID = parentId
        }
        return await networkService.perform(factory.listFolder(request))
    }
    
    public func createFolder(name: String, parentId: UInt32? = nil) async -> Result<Materials_CreateFolderResponse, NetworkError> {
        var request = Materials_CreateFolderRequest()
        request.name = name
        if let parentId = parentId {
            request.parentID = parentId
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
        return await networkService.perform(factory.renameNode(request))
    }
    
    public func deleteNode(nodeId: UInt32) async -> Result<Materials_DeleteNodeResponse, NetworkError> {
        var request = Materials_DeleteNodeRequest()
        request.nodeID = nodeId
        return await networkService.perform(factory.deleteNode(request))
    }
    
    // MARK: - Coach
    
    func ask(conversationId: String? = nil, question: String, resumeProfile: User_ResumeProfile? = nil, contextChunks: [Coach_ContextChunk] = []) async -> Result<Coach_AskResponse, NetworkError> {
        var request = Coach_AskRequest()
        if let conversationId = conversationId {
            request.conversationID = conversationId
        }
        request.question = question
        if let resumeProfile = resumeProfile {
            request.resumeProfile = resumeProfile
        }
        request.contextChunks = contextChunks
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
    
    // MARK: - Calendar
    
    func createCalendar_Event(event: Calendar_Event) async -> Result<Calendar_CreateEventResponse, NetworkError> {
        var request = Calendar_CreateEventRequest()
        request.event = event
        return await networkService.perform(factory.createEvent(request))
    }
    
    public func getCalendar_Event(id: String) async -> Result<Calendar_GetEventResponse, NetworkError> {
        var request = Calendar_GetEventRequest()
        request.id = id
        return await networkService.perform(factory.getEvent(request))
    }
    
    func updateCalendar_Event(id: String, patch: Calendar_EventPatch) async -> Result<Calendar_UpdateEventResponse, NetworkError> {
        var request = Calendar_UpdateEventRequest()
        request.id = id
        request.patch = patch
        return await networkService.perform(factory.updateEvent(request))
    }
    
    public func deleteCalendar_Event(id: String) async -> Result<Calendar_DeleteEventResponse, NetworkError> {
        var request = Calendar_DeleteEventRequest()
        request.id = id
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
    
    func listUpcoming(limit: Int32, fromTime: SwiftProtobuf.Google_Protobuf_Timestamp? = nil) async -> Result<Calendar_ListUpcomingResponse, NetworkError> {
        var request = Calendar_ListUpcomingRequest()
        request.limit = limit
        if let fromTime = fromTime {
            request.fromTime = fromTime
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

    public func getResumeProfile(accessToken: String?) async throws -> User_GetResumeProfileResponse {
        let request = User_GetResumeProfileRequest()
        let options = callOptions(with: accessToken)
        let call = client.getResumeProfile(request, callOptions: options)
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

    private func callOptions(with token: String?) -> CallOptions {
        var metadata = HPACKHeaders()
        if let token = token, !token.isEmpty {
            metadata.add(name: "authorization", value: "Bearer \(token)")
        }
        return CallOptions(customMetadata: metadata)
    }
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
