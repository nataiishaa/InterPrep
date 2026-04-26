import Foundation
import GRPC
import NIOCore
import NIOHPACK
import SwiftProtobuf

// swiftlint:disable file_length
// swiftlint:disable:next type_body_length
public final class NetworkServiceV2: ObservableObject {
    public static let shared = NetworkServiceV2()
    
    private let grpcClient: BackendGatewayGRPCClient
    private let tokenStorage: TokenStorage
    private let sessionManager: SessionManager
    
    private init() {
        let tokenStorage = TokenStorage()
        self.tokenStorage = tokenStorage
        self.sessionManager = SessionManager()
        
        do {
            self.grpcClient = try BackendGatewayGRPCClient(host: "api.interprep.ru", port: 443)
        } catch {
            fatalError("Failed to initialize gRPC client: \(error)")
        }
    }
    
    public func setSessionDelegate(_ delegate: SessionInvalidationDelegate?) async {
        await sessionManager.setDelegate(delegate)
    }
    
    // MARK: - gRPC with token refresh
    
    /// Executes an authenticated gRPC call. On `.unauthenticated`, refreshes
    /// the access token and retries once.
    private func performGRPC<Response>(
        _ operation: @escaping (BackendGatewayGRPCClient, String?) async throws -> Response
    ) async -> Result<Response, NetworkError> {
        let token = await tokenStorage.getAccessToken()
        do {
            return .success(try await operation(grpcClient, token))
        } catch {
            print("[gRPC] error: type=\(type(of: error)) desc=\(String(describing: error))")
            guard let status = error as? GRPCStatus, status.code == .unauthenticated else {
                if let api = apiErrorFromGRPC(error) { return .failure(.apiError(api)) }
                return .failure(.transportError(error))
            }
            let refreshed = await refreshTokens()
            guard refreshed else {
                await sessionManager.handleUnauthorized()
                return .failure(.unauthorized)
            }
            let newToken = await tokenStorage.getAccessToken()
            do {
                return .success(try await operation(grpcClient, newToken))
            } catch {
                await sessionManager.handleUnauthorized()
                if let api = apiErrorFromGRPC(error) { return .failure(.apiError(api)) }
                return .failure(.transportError(error))
            }
        }
    }
    
    /// Refresh tokens via gRPC directly (not through `performGRPC` to avoid recursion).
    private func refreshTokens() async -> Bool {
        guard let refreshToken = await tokenStorage.getRefreshToken() else {
            await tokenStorage.clearTokens()
            return false
        }
        
        var request = Auth_RefreshRequest()
        request.refreshToken = refreshToken
        
        do {
            let response = try await grpcClient.refresh(request: request)
            await tokenStorage.setTokens(
                accessToken: response.accessToken,
                refreshToken: refreshToken
            )
            return true
        } catch {
            await tokenStorage.clearTokens()
            return false
        }
    }
    
    // MARK: - Auth (no existing token needed)
    
    public func register(firstName: String, lastName: String, email: String, password: String, deviceId: String? = nil) async -> Result<Auth_RegisterResponse, NetworkError> {
        var request = Auth_RegisterRequest()
        request.firstName = firstName
        request.lastName = lastName
        request.email = email
        request.password = password
        if let deviceId = deviceId {
            request.deviceID = deviceId
        }
        
        do {
            let response = try await grpcClient.register(request: request)
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
    
    public func login(email: String, password: String, deviceId: String? = nil) async -> Result<Auth_LoginResponse, NetworkError> {
        var request = Auth_LoginRequest()
        request.email = email
        request.password = password
        if let deviceId = deviceId {
            request.deviceID = deviceId
        }
        
        do {
            let response = try await grpcClient.login(request: request)
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
    
    public func refresh(refreshToken: String, deviceId: String? = nil) async -> Result<Auth_RefreshResponse, NetworkError> {
        var request = Auth_RefreshRequest()
        request.refreshToken = refreshToken
        if let deviceId = deviceId {
            request.deviceID = deviceId
        }
        
        do {
            let response = try await grpcClient.refresh(request: request)
            await tokenStorage.setTokens(
                accessToken: response.accessToken,
                refreshToken: refreshToken
            )
            return .success(response)
        } catch {
            if let api = apiErrorFromGRPC(error) { return .failure(.apiError(api)) }
            return .failure(.transportError(error))
        }
    }
    
    public func checkPasswordResetEmail(email: String) async -> Result<Auth_PasswordResetCheckEmailResponse, NetworkError> {
        var request = Auth_PasswordResetCheckEmailRequest()
        request.email = email
        
        do {
            let response = try await grpcClient.checkPasswordResetEmail(request: request)
            return .success(response)
        } catch {
            if let api = apiErrorFromGRPC(error) { return .failure(.apiError(api)) }
            return .failure(.transportError(error))
        }
    }
    
    public func sendPasswordResetCode(email: String) async -> Result<Auth_PasswordResetSendCodeResponse, NetworkError> {
        var request = Auth_PasswordResetSendCodeRequest()
        request.email = email
        
        do {
            let response = try await grpcClient.sendPasswordResetCode(request: request)
            return .success(response)
        } catch {
            if let api = apiErrorFromGRPC(error) { return .failure(.apiError(api)) }
            return .failure(.transportError(error))
        }
    }
    
    public func verifyPasswordReset(email: String, code: String, password: String) async -> Result<Auth_PasswordResetVerifyResponse, NetworkError> {
        var request = Auth_PasswordResetVerifyRequest()
        request.email = email
        request.code = code
        request.password = password
        
        do {
            let response = try await grpcClient.verifyPasswordReset(request: request)
            return .success(response)
        } catch {
            if let api = apiErrorFromGRPC(error) { return .failure(.apiError(api)) }
            return .failure(.transportError(error))
        }
    }
    
    // MARK: - User
    
    public func getMe() async -> Result<User_GetMeResponse, NetworkError> {
        await performGRPC { client, token in
            try await client.getMe(accessToken: token)
        }
    }
    
    public func getUser_ResumeProfile() async -> Result<User_GetResumeProfileResponse, NetworkError> {
        await performGRPC { client, token in
            try await client.getResumeProfile(accessToken: token)
        }
    }
    
    public func updateUser_ResumeProfile(userId: UInt32, profile: User_ResumeProfile) async -> Result<User_UpdateResumeProfileResponse, NetworkError> {
        var request = User_UpdateResumeProfileRequest()
        request.userID = userId
        request.profile = profile
        return await performGRPC { client, token in
            try await client.updateResumeProfile(request: request, accessToken: token)
        }
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
        return await performGRPC { client, token in
            try await client.updateUserProfile(request: request, accessToken: token)
        }
    }
    
    public func deleteAccount(password: String) async -> Result<User_DeleteAccountResponse, NetworkError> {
        var request = User_DeleteAccountRequest()
        request.password = password
        let result = await performGRPC { client, token in
            try await client.deleteAccount(request: request, accessToken: token)
        }
        if case .success(let response) = result, response.deleted {
            await tokenStorage.clearTokens()
        }
        return result
    }
    
    public func getProfilePhoto() async -> Result<User_GetProfilePhotoResponse, NetworkError> {
        await performGRPC { client, token in
            try await client.getProfilePhoto(accessToken: token)
        }
    }
    
    public func uploadProfilePhoto(imageData: Data, filename: String = "photo.jpg", mimeType: String = "image/jpeg") async -> Result<User_UploadProfilePhotoResponse, NetworkError> {
        var request = User_UploadProfilePhotoRequest()
        request.fileContent = imageData
        request.filename = filename
        request.mimeType = mimeType
        return await performGRPC { client, token in
            try await client.uploadProfilePhoto(request: request, accessToken: token)
        }
    }
    
    // MARK: - Jobs
    
    public func searchJobs(page: Int = 0, perPage: Int = 20) async -> Result<Jobs_SearchJobsResponse, NetworkError> {
        await performGRPC { client, token in
            try await client.searchJobs(page: page, perPage: perPage, accessToken: token)
        }
    }
    
    public func addFavorite(vacancyId: String) async -> Result<Jobs_AddFavoriteResponse, NetworkError> {
        await performGRPC { client, token in
            try await client.addFavorite(vacancyId: vacancyId, accessToken: token)
        }
    }
    
    public func removeFavorite(vacancyId: String) async -> Result<Jobs_RemoveFavoriteResponse, NetworkError> {
        await performGRPC { client, token in
            try await client.removeFavorite(vacancyId: vacancyId, accessToken: token)
        }
    }
    
    public func listFavorites() async -> Result<Jobs_ListFavoritesResponse, NetworkError> {
        await performGRPC { client, token in
            try await client.listFavorites(accessToken: token)
        }
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
        return await performGRPC { client, token in
            try await client.uploadFile(request: request, accessToken: token)
        }
    }
    
    public func downloadFile(materialId: String) async -> Result<Materials_DownloadFileResponse, NetworkError> {
        var request = Materials_DownloadFileRequest()
        request.materialID = materialId
        return await performGRPC { client, token in
            try await client.downloadFile(request: request, accessToken: token)
        }
    }
    
    public func listFolder(parentId: UInt32? = nil) async -> Result<Materials_ListFolderResponse, NetworkError> {
        var request = Materials_ListFolderRequest()
        if let parentId = parentId {
            request.parentID = parentId
        }
        print("[NetworkService] listFolder parentId=\(String(describing: parentId))")
        let result = await performGRPC { client, token in
            try await client.listFolder(request: request, accessToken: token)
        }
        if case .failure(let error) = result {
            print("[NetworkService] listFolder failed: \(error)")
        }
        return result
    }
    
    public func createFolder(name: String, parentId: UInt32? = nil) async -> Result<Materials_CreateFolderResponse, NetworkError> {
        var request = Materials_CreateFolderRequest()
        request.name = name
        if let parentId = parentId {
            request.parentID = parentId
        }
        return await performGRPC { client, token in
            try await client.createFolder(request: request, accessToken: token)
        }
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
        return await performGRPC { client, token in
            try await client.createLink(request: request, accessToken: token)
        }
    }
    
    public func renameNode(nodeId: UInt32, newName: String) async -> Result<Materials_RenameNodeResponse, NetworkError> {
        var request = Materials_RenameNodeRequest()
        request.nodeID = nodeId
        request.newName = newName
        return await performGRPC { client, token in
            try await client.renameNode(request: request, accessToken: token)
        }
    }
    
    public func deleteNode(nodeId: UInt32) async -> Result<Materials_DeleteNodeResponse, NetworkError> {
        var request = Materials_DeleteNodeRequest()
        request.nodeID = nodeId
        return await performGRPC { client, token in
            try await client.deleteNode(request: request, accessToken: token)
        }
    }
    
    public func recentFiles() async -> Result<Materials_RecentFilesResponse, NetworkError> {
        let request = Materials_RecentFilesRequest()
        print("[NetworkService] recentFiles")
        let result = await performGRPC { client, token in
            try await client.recentFiles(request: request, accessToken: token)
        }
        if case .failure(let error) = result {
            if case .apiError(let apiError) = error,
               apiError.serverMessage.contains("unknown method") || apiError.serverMessage.contains("unimplemented") {
                print("[NetworkService] recentFiles: method not implemented on backend (expected)")
            } else {
                print("[NetworkService] recentFiles failed: \(error)")
            }
        }
        return result
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
        return await performGRPC { client, token in
            try await client.ask(request: request, accessToken: token)
        }
    }
    
    public func parseResume(materialId: String) async -> Result<Coach_ParseResumeResponse, NetworkError> {
        var request = Coach_ParseResumeRequest()
        request.materialID = materialId
        return await performGRPC { client, token in
            try await client.parseResume(request: request, accessToken: token)
        }
    }
    
    public func uploadAndParseResume(fileContent: Data, filename: String) async -> Result<Coach_UploadAndParseResumeResponse, NetworkError> {
        var request = Coach_UploadAndParseResumeRequest()
        request.fileContent = fileContent
        request.filename = filename
        return await performGRPC { client, token in
            try await client.uploadAndParseResume(request: request, accessToken: token)
        }
    }
    
    func answerResume(sessionId: String, answers: [Coach_QuestionAnswer]) async -> Result<Coach_AnswerResumeResponse, NetworkError> {
        var request = Coach_AnswerResumeRequest()
        request.sessionID = sessionId
        request.answers = answers
        return await performGRPC { client, token in
            try await client.answerResume(request: request, accessToken: token)
        }
    }
    
    public func getResumeSession(sessionId: String) async -> Result<Coach_GetResumeSessionResponse, NetworkError> {
        var request = Coach_GetResumeSessionRequest()
        request.sessionID = sessionId
        return await performGRPC { client, token in
            try await client.getResumeSession(request: request, accessToken: token)
        }
    }
    
    public func prepareForVacancy(vacancyId: String) async -> Result<Coach_PrepareForVacancyResponse, NetworkError> {
        var request = Coach_PrepareForVacancyRequest()
        request.vacancyID = vacancyId
        return await performGRPC { client, token in
            try await client.prepareForVacancy(request: request, accessToken: token)
        }
    }
    
    public func reviewResume() async -> Result<Coach_ReviewResumeResponse, NetworkError> {
        let request = Coach_ReviewResumeRequest()
        return await performGRPC { client, token in
            try await client.reviewResume(request: request, accessToken: token)
        }
    }
    
    public func clearChatHistory(conversationId: String? = nil) async -> Result<Coach_ClearChatHistoryResponse, NetworkError> {
        var request = Coach_ClearChatHistoryRequest()
        if let conversationId = conversationId {
            request.conversationID = conversationId
        }
        return await performGRPC { client, token in
            try await client.clearChatHistory(request: request, accessToken: token)
        }
    }
    
    public func getCoachChatHistory(pageSize: Int32 = 50, pageOffset: Int32 = 0) async -> Result<Coach_GetCoachChatHistoryResponse, NetworkError> {
        var request = Coach_GetCoachChatHistoryRequest()
        request.pageSize = pageSize
        request.pageOffset = pageOffset
        return await performGRPC { client, token in
            try await client.getCoachChatHistory(request: request, accessToken: token)
        }
    }
    
    public func addChatMessage(conversationId: String?, content: String, owner: Coach_ChatMessageOwner) async -> Result<Coach_AddChatMessageResponse, NetworkError> {
        var request = Coach_AddChatMessageRequest()
        if let conversationId = conversationId {
            request.conversationID = conversationId
        }
        request.content = content
        request.owner = owner
        return await performGRPC { client, token in
            try await client.addChatMessage(request: request, accessToken: token)
        }
    }
    
    // MARK: - Calendar
    
    public struct CreateEventParams {
        public let title: String
        public let description: String
        public let startTime: Date
        public let endTime: Date
        public let eventType: Calendar_EventType
        public let location: String?
        public let reminderEnabled: Bool
        public let reminderMinutes: Int32
        
        public init(
            title: String,
            description: String,
            startTime: Date,
            endTime: Date,
            eventType: Calendar_EventType,
            location: String? = nil,
            reminderEnabled: Bool = false,
            reminderMinutes: Int32 = 15
        ) {
            self.title = title
            self.description = description
            self.startTime = startTime
            self.endTime = endTime
            self.eventType = eventType
            self.location = location
            self.reminderEnabled = reminderEnabled
            self.reminderMinutes = reminderMinutes
        }
    }
    
    public struct UpdateEventParams {
        public let id: String
        public let title: String?
        public let description: String?
        public let startTime: Date?
        public let endTime: Date?
        public let eventType: Calendar_EventType?
        public let location: String?
        public let reminderEnabled: Bool?
        public let reminderMinutes: Int32?
        public let completed: Bool?
        
        public init(
            id: String,
            title: String? = nil,
            description: String? = nil,
            startTime: Date? = nil,
            endTime: Date? = nil,
            eventType: Calendar_EventType? = nil,
            location: String? = nil,
            reminderEnabled: Bool? = nil,
            reminderMinutes: Int32? = nil,
            completed: Bool? = nil
        ) {
            self.id = id
            self.title = title
            self.description = description
            self.startTime = startTime
            self.endTime = endTime
            self.eventType = eventType
            self.location = location
            self.reminderEnabled = reminderEnabled
            self.reminderMinutes = reminderMinutes
            self.completed = completed
        }
    }
    
    public func createEvent(params: CreateEventParams) async -> Result<Calendar_CreateEventResponse, NetworkError> {
        var event = Calendar_Event()
        event.title = params.title
        event.description_p = params.description
        event.eventType = params.eventType
        event.startTime = params.startTime.toProtoTimestamp()
        event.endTime = params.endTime.toProtoTimestamp()
        if let location = params.location {
            event.location = location
        }
        event.reminderEnabled = params.reminderEnabled
        event.reminderMinutes = params.reminderMinutes
        
        var request = Calendar_CreateEventRequest()
        request.event = event
        return await performGRPC { client, token in
            try await client.createEvent(request: request, accessToken: token)
        }
    }
    
    // swiftlint:disable:next function_parameter_count
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
        await createEvent(params: CreateEventParams(
            title: title,
            description: description,
            startTime: startTime,
            endTime: endTime,
            eventType: eventType,
            location: location,
            reminderEnabled: reminderEnabled,
            reminderMinutes: reminderMinutes
        ))
    }
    
    public func getCalendar_Event(id: String) async -> Result<Calendar_GetEventResponse, NetworkError> {
        var request = Calendar_GetEventRequest()
        request.id = id
        return await performGRPC { client, token in
            try await client.getEvent(request: request, accessToken: token)
        }
    }
    
    public func updateEvent(params: UpdateEventParams) async -> Result<Calendar_UpdateEventResponse, NetworkError> {
        var patch = Calendar_EventPatch()
        if let title = params.title {
            patch.title = title
        }
        if let description = params.description {
            patch.description_p = description
        }
        if let startTime = params.startTime {
            patch.startTime = startTime.toProtoTimestamp()
        }
        if let endTime = params.endTime {
            patch.endTime = endTime.toProtoTimestamp()
        }
        if let eventType = params.eventType {
            patch.eventType = eventType
        }
        if let location = params.location {
            patch.location = location
        }
        if let reminderEnabled = params.reminderEnabled {
            patch.reminderEnabled = reminderEnabled
        }
        if let reminderMinutes = params.reminderMinutes {
            patch.reminderMinutes = reminderMinutes
        }
        if let completed = params.completed {
            patch.completed = completed
        }
        
        var request = Calendar_UpdateEventRequest()
        request.id = params.id
        request.patch = patch
        return await performGRPC { client, token in
            try await client.updateEvent(request: request, accessToken: token)
        }
    }
    
    // swiftlint:disable:next function_parameter_count
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
        await updateEvent(params: UpdateEventParams(
            id: id,
            title: title,
            description: description,
            startTime: startTime,
            endTime: endTime,
            eventType: eventType,
            location: location,
            reminderEnabled: reminderEnabled,
            reminderMinutes: reminderMinutes,
            completed: completed
        ))
    }
    
    public func deleteEvent(id: String) async -> Result<Calendar_DeleteEventResponse, NetworkError> {
        var request = Calendar_DeleteEventRequest()
        request.id = id
        return await performGRPC { client, token in
            try await client.deleteEvent(request: request, accessToken: token)
        }
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
        return await performGRPC { client, token in
            try await client.listEvents(request: request, accessToken: token)
        }
    }
    
    public func listUpcoming(limit: Int32, fromTime: Date) async -> Result<Calendar_ListUpcomingResponse, NetworkError> {
        var request = Calendar_ListUpcomingRequest()
        request.limit = limit
        request.fromTime = fromTime.toProtoTimestamp()
        return await performGRPC { client, token in
            try await client.listUpcoming(request: request, accessToken: token)
        }
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

// MARK: - gRPC Client

public final class BackendGatewayGRPCClient: Sendable {
    private let connection: ClientConnection
    private let group: EventLoopGroup
    private let client: Gateway_BackendGatewayClient

    private static let defaultCallOptions = CallOptions(timeLimit: .timeout(.seconds(15)))

    public init(host: String = "api.interprep.ru", port: Int = 443) throws {
        self.group = PlatformSupport.makeEventLoopGroup(loopCount: 1)
        let builder = ClientConnection
            .usingTLSBackedByNIOSSL(on: group)
            .withMaximumReceiveMessageLength(16 * 1024 * 1024)
        self.connection = builder.connect(host: host, port: port)
        self.client = Gateway_BackendGatewayClient(channel: connection)
    }

    deinit {
        try? connection.close().wait()
    }

    // MARK: - Auth

    public func register(request: Auth_RegisterRequest) async throws -> Auth_RegisterResponse {
        let call = client.register(request, callOptions: Self.defaultCallOptions)
        return try await eventLoopFutureToAsync(call.response)
    }

    public func login(request: Auth_LoginRequest) async throws -> Auth_LoginResponse {
        let call = client.login(request, callOptions: Self.defaultCallOptions)
        return try await eventLoopFutureToAsync(call.response)
    }

    public func refresh(request: Auth_RefreshRequest) async throws -> Auth_RefreshResponse {
        let call: UnaryCall<Auth_RefreshRequest, Auth_RefreshResponse> = connection.makeUnaryCall(
            path: "/gateway.BackendGateway/Refresh",
            request: request,
            callOptions: Self.defaultCallOptions,
            interceptors: []
        )
        return try await eventLoopFutureToAsync(call.response)
    }

    public func checkPasswordResetEmail(request: Auth_PasswordResetCheckEmailRequest) async throws -> Auth_PasswordResetCheckEmailResponse {
        let call: UnaryCall<Auth_PasswordResetCheckEmailRequest, Auth_PasswordResetCheckEmailResponse> = connection.makeUnaryCall(
            path: "/gateway.BackendGateway/CheckPasswordResetEmail",
            request: request,
            callOptions: Self.defaultCallOptions,
            interceptors: []
        )
        return try await eventLoopFutureToAsync(call.response)
    }

    public func sendPasswordResetCode(request: Auth_PasswordResetSendCodeRequest) async throws -> Auth_PasswordResetSendCodeResponse {
        let call = client.sendPasswordResetCode(request, callOptions: Self.defaultCallOptions)
        return try await eventLoopFutureToAsync(call.response)
    }

    public func verifyPasswordReset(request: Auth_PasswordResetVerifyRequest) async throws -> Auth_PasswordResetVerifyResponse {
        let call = client.verifyPasswordReset(request, callOptions: Self.defaultCallOptions)
        return try await eventLoopFutureToAsync(call.response)
    }

    // MARK: - User

    public func getMe(accessToken: String?) async throws -> User_GetMeResponse {
        let request = User_GetMeRequest()
        let call: UnaryCall<User_GetMeRequest, User_GetMeResponse> = connection.makeUnaryCall(
            path: "/gateway.BackendGateway/GetMe",
            request: request,
            callOptions: callOptions(with: accessToken),
            interceptors: []
        )
        return try await eventLoopFutureToAsync(call.response)
    }

    public func getResumeProfile(accessToken: String?) async throws -> User_GetResumeProfileResponse {
        let request = User_GetResumeProfileRequest()
        let call = client.getResumeProfile(request, callOptions: callOptions(with: accessToken))
        return try await eventLoopFutureToAsync(call.response)
    }

    public func updateResumeProfile(request: User_UpdateResumeProfileRequest, accessToken: String?) async throws -> User_UpdateResumeProfileResponse {
        let call: UnaryCall<User_UpdateResumeProfileRequest, User_UpdateResumeProfileResponse> = connection.makeUnaryCall(
            path: "/gateway.BackendGateway/UpdateResumeProfile",
            request: request,
            callOptions: callOptions(with: accessToken),
            interceptors: []
        )
        return try await eventLoopFutureToAsync(call.response)
    }

    public func updateUserProfile(request: User_UpdateUserProfileRequest, accessToken: String?) async throws -> User_UpdateUserProfileResponse {
        let call: UnaryCall<User_UpdateUserProfileRequest, User_UpdateUserProfileResponse> = connection.makeUnaryCall(
            path: "/gateway.BackendGateway/UpdateUserProfile",
            request: request,
            callOptions: callOptions(with: accessToken),
            interceptors: []
        )
        return try await eventLoopFutureToAsync(call.response)
    }

    public func deleteAccount(request: User_DeleteAccountRequest, accessToken: String?) async throws -> User_DeleteAccountResponse {
        let call: UnaryCall<User_DeleteAccountRequest, User_DeleteAccountResponse> = connection.makeUnaryCall(
            path: "/gateway.BackendGateway/DeleteAccount",
            request: request,
            callOptions: callOptions(with: accessToken),
            interceptors: []
        )
        return try await eventLoopFutureToAsync(call.response)
    }

    public func getProfilePhoto(accessToken: String?) async throws -> User_GetProfilePhotoResponse {
        let request = User_GetProfilePhotoRequest()
        let call: UnaryCall<User_GetProfilePhotoRequest, User_GetProfilePhotoResponse> = connection.makeUnaryCall(
            path: "/gateway.BackendGateway/GetProfilePhoto",
            request: request,
            callOptions: callOptions(with: accessToken),
            interceptors: []
        )
        return try await eventLoopFutureToAsync(call.response)
    }

    public func uploadProfilePhoto(request: User_UploadProfilePhotoRequest, accessToken: String?) async throws -> User_UploadProfilePhotoResponse {
        let call: UnaryCall<User_UploadProfilePhotoRequest, User_UploadProfilePhotoResponse> = connection.makeUnaryCall(
            path: "/gateway.BackendGateway/UploadProfilePhoto",
            request: request,
            callOptions: callOptionsForUpload(with: accessToken),
            interceptors: []
        )
        return try await eventLoopFutureToAsync(call.response)
    }

    // MARK: - Jobs

    public func searchJobs(page: Int = 0, perPage: Int = 20, accessToken: String?) async throws -> Jobs_SearchJobsResponse {
        var request = Jobs_SearchJobsRequest()
        request.page = Int32(page)
        request.perPage = Int32(perPage)
        let call = client.searchJobs(request, callOptions: callOptions(with: accessToken))
        return try await eventLoopFutureToAsync(call.response)
    }

    public func listFavorites(accessToken: String?) async throws -> Jobs_ListFavoritesResponse {
        let request = Jobs_ListFavoritesRequest()
        let call = client.listFavorites(request, callOptions: callOptions(with: accessToken))
        return try await eventLoopFutureToAsync(call.response)
    }
    
    public func addFavorite(vacancyId: String, accessToken: String?) async throws -> Jobs_AddFavoriteResponse {
        var request = Jobs_AddFavoriteRequest()
        request.vacancyID = vacancyId
        let call: UnaryCall<Jobs_AddFavoriteRequest, Jobs_AddFavoriteResponse> = connection.makeUnaryCall(
            path: "/gateway.BackendGateway/AddFavorite",
            request: request,
            callOptions: callOptions(with: accessToken),
            interceptors: []
        )
        return try await eventLoopFutureToAsync(call.response)
    }
    
    public func removeFavorite(vacancyId: String, accessToken: String?) async throws -> Jobs_RemoveFavoriteResponse {
        var request = Jobs_RemoveFavoriteRequest()
        request.vacancyID = vacancyId
        let call: UnaryCall<Jobs_RemoveFavoriteRequest, Jobs_RemoveFavoriteResponse> = connection.makeUnaryCall(
            path: "/gateway.BackendGateway/RemoveFavorite",
            request: request,
            callOptions: callOptions(with: accessToken),
            interceptors: []
        )
        return try await eventLoopFutureToAsync(call.response)
    }
    
    // MARK: - Materials

    public func uploadFile(request: Materials_UploadFileRequest, accessToken: String?) async throws -> Materials_UploadFileResponse {
        let call: UnaryCall<Materials_UploadFileRequest, Materials_UploadFileResponse> = connection.makeUnaryCall(
            path: "/gateway.BackendGateway/UploadFile",
            request: request,
            callOptions: callOptions(with: accessToken),
            interceptors: []
        )
        return try await eventLoopFutureToAsync(call.response)
    }
    
    public func downloadFile(request: Materials_DownloadFileRequest, accessToken: String?) async throws -> Materials_DownloadFileResponse {
        let call: UnaryCall<Materials_DownloadFileRequest, Materials_DownloadFileResponse> = connection.makeUnaryCall(
            path: "/gateway.BackendGateway/DownloadFile",
            request: request,
            callOptions: callOptions(with: accessToken),
            interceptors: []
        )
        return try await eventLoopFutureToAsync(call.response)
    }
    
    public func listFolder(request: Materials_ListFolderRequest, accessToken: String?) async throws -> Materials_ListFolderResponse {
        let call: UnaryCall<Materials_ListFolderRequest, Materials_ListFolderResponse> = connection.makeUnaryCall(
            path: "/gateway.BackendGateway/ListFolder",
            request: request,
            callOptions: callOptions(with: accessToken),
            interceptors: []
        )
        return try await eventLoopFutureToAsync(call.response)
    }
    
    public func createFolder(request: Materials_CreateFolderRequest, accessToken: String?) async throws -> Materials_CreateFolderResponse {
        let call: UnaryCall<Materials_CreateFolderRequest, Materials_CreateFolderResponse> = connection.makeUnaryCall(
            path: "/gateway.BackendGateway/CreateFolder",
            request: request,
            callOptions: callOptions(with: accessToken),
            interceptors: []
        )
        return try await eventLoopFutureToAsync(call.response)
    }

    public func createLink(request: Materials_CreateLinkRequest, accessToken: String?) async throws -> Materials_CreateLinkResponse {
        let call: UnaryCall<Materials_CreateLinkRequest, Materials_CreateLinkResponse> = connection.makeUnaryCall(
            path: "/gateway.BackendGateway/CreateLink",
            request: request,
            callOptions: callOptions(with: accessToken),
            interceptors: []
        )
        return try await eventLoopFutureToAsync(call.response)
    }
    
    public func renameNode(request: Materials_RenameNodeRequest, accessToken: String?) async throws -> Materials_RenameNodeResponse {
        let call: UnaryCall<Materials_RenameNodeRequest, Materials_RenameNodeResponse> = connection.makeUnaryCall(
            path: "/gateway.BackendGateway/RenameNode",
            request: request,
            callOptions: callOptions(with: accessToken),
            interceptors: []
        )
        return try await eventLoopFutureToAsync(call.response)
    }
    
    public func deleteNode(request: Materials_DeleteNodeRequest, accessToken: String?) async throws -> Materials_DeleteNodeResponse {
        let call: UnaryCall<Materials_DeleteNodeRequest, Materials_DeleteNodeResponse> = connection.makeUnaryCall(
            path: "/gateway.BackendGateway/DeleteNode",
            request: request,
            callOptions: callOptions(with: accessToken),
            interceptors: []
        )
        return try await eventLoopFutureToAsync(call.response)
    }
    
    public func recentFiles(request: Materials_RecentFilesRequest, accessToken: String?) async throws -> Materials_RecentFilesResponse {
        let call: UnaryCall<Materials_RecentFilesRequest, Materials_RecentFilesResponse> = connection.makeUnaryCall(
            path: "/gateway.BackendGateway/RecentFiles",
            request: request,
            callOptions: callOptions(with: accessToken),
            interceptors: []
        )
        return try await eventLoopFutureToAsync(call.response)
    }
    
    // MARK: - Coach (LLM calls use 120s timeout)

    public func ask(request: Coach_AskRequest, accessToken: String?) async throws -> Coach_AskResponse {
        let call: UnaryCall<Coach_AskRequest, Coach_AskResponse> = connection.makeUnaryCall(
            path: "/gateway.BackendGateway/Ask",
            request: request,
            callOptions: callOptionsForLLM(with: accessToken),
            interceptors: []
        )
        return try await eventLoopFutureToAsync(call.response)
    }

    public func parseResume(request: Coach_ParseResumeRequest, accessToken: String?) async throws -> Coach_ParseResumeResponse {
        let call: UnaryCall<Coach_ParseResumeRequest, Coach_ParseResumeResponse> = connection.makeUnaryCall(
            path: "/gateway.BackendGateway/ParseResume",
            request: request,
            callOptions: callOptionsForLLM(with: accessToken),
            interceptors: []
        )
        return try await eventLoopFutureToAsync(call.response)
    }
    
    public func prepareForVacancy(request: Coach_PrepareForVacancyRequest, accessToken: String?) async throws -> Coach_PrepareForVacancyResponse {
        let call: UnaryCall<Coach_PrepareForVacancyRequest, Coach_PrepareForVacancyResponse> = connection.makeUnaryCall(
            path: "/gateway.BackendGateway/PrepareForVacancy",
            request: request,
            callOptions: callOptionsForLLM(with: accessToken),
            interceptors: []
        )
        return try await eventLoopFutureToAsync(call.response)
    }
    
    public func reviewResume(request: Coach_ReviewResumeRequest, accessToken: String?) async throws -> Coach_ReviewResumeResponse {
        let call: UnaryCall<Coach_ReviewResumeRequest, Coach_ReviewResumeResponse> = connection.makeUnaryCall(
            path: "/gateway.BackendGateway/ReviewResume",
            request: request,
            callOptions: callOptionsForLLM(with: accessToken),
            interceptors: []
        )
        return try await eventLoopFutureToAsync(call.response)
    }
    
    public func clearChatHistory(request: Coach_ClearChatHistoryRequest, accessToken: String?) async throws -> Coach_ClearChatHistoryResponse {
        let call: UnaryCall<Coach_ClearChatHistoryRequest, Coach_ClearChatHistoryResponse> = connection.makeUnaryCall(
            path: "/gateway.BackendGateway/ClearChatHistory",
            request: request,
            callOptions: callOptions(with: accessToken),
            interceptors: []
        )
        return try await eventLoopFutureToAsync(call.response)
    }
    
    public func uploadAndParseResume(request: Coach_UploadAndParseResumeRequest, accessToken: String?) async throws -> Coach_UploadAndParseResumeResponse {
        let call: UnaryCall<Coach_UploadAndParseResumeRequest, Coach_UploadAndParseResumeResponse> = connection.makeUnaryCall(
            path: "/gateway.BackendGateway/UploadAndParseResume",
            request: request,
            callOptions: callOptionsForLLM(with: accessToken),
            interceptors: []
        )
        return try await eventLoopFutureToAsync(call.response)
    }

    public func answerResume(request: Coach_AnswerResumeRequest, accessToken: String?) async throws -> Coach_AnswerResumeResponse {
        let call: UnaryCall<Coach_AnswerResumeRequest, Coach_AnswerResumeResponse> = connection.makeUnaryCall(
            path: "/gateway.BackendGateway/AnswerResume",
            request: request,
            callOptions: callOptionsForLLM(with: accessToken),
            interceptors: []
        )
        return try await eventLoopFutureToAsync(call.response)
    }

    public func getResumeSession(request: Coach_GetResumeSessionRequest, accessToken: String?) async throws -> Coach_GetResumeSessionResponse {
        let call: UnaryCall<Coach_GetResumeSessionRequest, Coach_GetResumeSessionResponse> = connection.makeUnaryCall(
            path: "/gateway.BackendGateway/GetResumeSession",
            request: request,
            callOptions: callOptions(with: accessToken),
            interceptors: []
        )
        return try await eventLoopFutureToAsync(call.response)
    }
    
    public func getCoachChatHistory(request: Coach_GetCoachChatHistoryRequest, accessToken: String?) async throws -> Coach_GetCoachChatHistoryResponse {
        let call: UnaryCall<Coach_GetCoachChatHistoryRequest, Coach_GetCoachChatHistoryResponse> = connection.makeUnaryCall(
            path: "/gateway.BackendGateway/GetCoachChatHistory",
            request: request,
            callOptions: callOptions(with: accessToken),
            interceptors: []
        )
        return try await eventLoopFutureToAsync(call.response)
    }
    
    public func addChatMessage(request: Coach_AddChatMessageRequest, accessToken: String?) async throws -> Coach_AddChatMessageResponse {
        let call: UnaryCall<Coach_AddChatMessageRequest, Coach_AddChatMessageResponse> = connection.makeUnaryCall(
            path: "/gateway.BackendGateway/AddChatMessage",
            request: request,
            callOptions: callOptions(with: accessToken),
            interceptors: []
        )
        return try await eventLoopFutureToAsync(call.response)
    }
    
    // MARK: - Calendar

    public func listEvents(request: Calendar_ListEventsRequest, accessToken: String?) async throws -> Calendar_ListEventsResponse {
        let call: UnaryCall<Calendar_ListEventsRequest, Calendar_ListEventsResponse> = connection.makeUnaryCall(
            path: "/gateway.BackendGateway/ListEvents",
            request: request,
            callOptions: callOptions(with: accessToken),
            interceptors: []
        )
        return try await eventLoopFutureToAsync(call.response)
    }
    
    public func listUpcoming(request: Calendar_ListUpcomingRequest, accessToken: String?) async throws -> Calendar_ListUpcomingResponse {
        let call: UnaryCall<Calendar_ListUpcomingRequest, Calendar_ListUpcomingResponse> = connection.makeUnaryCall(
            path: "/gateway.BackendGateway/ListUpcoming",
            request: request,
            callOptions: callOptions(with: accessToken),
            interceptors: []
        )
        return try await eventLoopFutureToAsync(call.response)
    }
    
    public func createEvent(request: Calendar_CreateEventRequest, accessToken: String?) async throws -> Calendar_CreateEventResponse {
        let call: UnaryCall<Calendar_CreateEventRequest, Calendar_CreateEventResponse> = connection.makeUnaryCall(
            path: "/gateway.BackendGateway/CreateEvent",
            request: request,
            callOptions: callOptions(with: accessToken),
            interceptors: []
        )
        return try await eventLoopFutureToAsync(call.response)
    }
    
    public func getEvent(request: Calendar_GetEventRequest, accessToken: String?) async throws -> Calendar_GetEventResponse {
        let call: UnaryCall<Calendar_GetEventRequest, Calendar_GetEventResponse> = connection.makeUnaryCall(
            path: "/gateway.BackendGateway/GetEvent",
            request: request,
            callOptions: callOptions(with: accessToken),
            interceptors: []
        )
        return try await eventLoopFutureToAsync(call.response)
    }
    
    public func updateEvent(request: Calendar_UpdateEventRequest, accessToken: String?) async throws -> Calendar_UpdateEventResponse {
        let call: UnaryCall<Calendar_UpdateEventRequest, Calendar_UpdateEventResponse> = connection.makeUnaryCall(
            path: "/gateway.BackendGateway/UpdateEvent",
            request: request,
            callOptions: callOptions(with: accessToken),
            interceptors: []
        )
        return try await eventLoopFutureToAsync(call.response)
    }
    
    public func deleteEvent(request: Calendar_DeleteEventRequest, accessToken: String?) async throws -> Calendar_DeleteEventResponse {
        let call: UnaryCall<Calendar_DeleteEventRequest, Calendar_DeleteEventResponse> = connection.makeUnaryCall(
            path: "/gateway.BackendGateway/DeleteEvent",
            request: request,
            callOptions: callOptions(with: accessToken),
            interceptors: []
        )
        return try await eventLoopFutureToAsync(call.response)
    }
    
    // MARK: - Call Options
    
    private func callOptions(with token: String?) -> CallOptions {
        var metadata = HPACKHeaders()
        if let token = token, !token.isEmpty {
            metadata.add(name: "authorization", value: "Bearer \(token)")
        }
        return CallOptions(customMetadata: metadata, timeLimit: .timeout(.seconds(15)))
    }
    
    private func callOptionsForUpload(with token: String?) -> CallOptions {
        var metadata = HPACKHeaders()
        if let token = token, !token.isEmpty {
            metadata.add(name: "authorization", value: "Bearer \(token)")
        }
        return CallOptions(
            customMetadata: metadata,
            timeLimit: .timeout(.seconds(90))
        )
    }
    
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

// MARK: - Helpers

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
