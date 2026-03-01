import Foundation
import SwiftProtobuf

@MainActor
public final class NetworkServiceV2: ObservableObject {
    public static let shared = NetworkServiceV2()
    
    private let factory: URLRequestFactory
    private let networkService: AsyncNetworkService
    private let tokenStorage: TokenStorage
    
    private init() {
        self.tokenStorage = TokenStorage()
        
        self.factory = URLRequestFactory(
            networkProvider: DefaultNetworkProvider(
                scheme: "http",
                host: "193.124.33.223",
                port: 9090
            )
        )
        
        let tokenProvider = DefaultTokenProvider(tokenStorage: tokenStorage)
        self.networkService = AsyncNetworkService(
            tokenProvider: tokenProvider,
            responseObservers: [LoggingObserver()]
        )
    }
    
    // MARK: - Auth
    
    public func register(firstName: String, lastName: String, email: String, password: String) async -> Result<Gateway_RegisterResponse, NetworkError> {
        var request = Gateway_RegisterRequest()
        request.firstName = firstName
        request.lastName = lastName
        request.email = email
        request.password = password
        
        let result = await networkService.perform(factory.register(request))
        
        // Сохранить токены при успехе
        if case .success(let response) = result {
            await tokenStorage.setTokens(
                accessToken: response.accessToken,
                refreshToken: response.refreshToken
            )
        }
        
        return result
    }
    
    public func login(email: String, password: String) async -> Result<Gateway_LoginResponse, NetworkError> {
        var request = Gateway_LoginRequest()
        request.email = email
        request.password = password
        
        let result = await networkService.perform(factory.login(request))
        
        // Сохранить токены при успехе
        if case .success(let response) = result {
            await tokenStorage.setTokens(
                accessToken: response.accessToken,
                refreshToken: response.refreshToken
            )
        }
        
        return result
    }
    
    // MARK: - Jobs
    
    public func searchJobs(page: Int = 0, perPage: Int = 20) async -> Result<Gateway_SearchJobsResponse, NetworkError> {
        var request = Gateway_SearchJobsRequest()
        request.page = Int32(page)
        request.perPage = Int32(perPage)
        
        return await networkService.perform(factory.searchJobs(request))
    }
    
    public func addFavorite(vacancyId: String) async -> Result<Gateway_AddFavoriteResponse, NetworkError> {
        var request = Gateway_AddFavoriteRequest()
        request.vacancyID = vacancyId
        
        return await networkService.perform(factory.addFavorite(request))
    }
    
    public func removeFavorite(vacancyId: String) async -> Result<Gateway_RemoveFavoriteResponse, NetworkError> {
        var request = Gateway_RemoveFavoriteRequest()
        request.vacancyID = vacancyId
        
        return await networkService.perform(factory.removeFavorite(request))
    }
    
    public func listFavorites() async -> Result<Gateway_ListFavoritesResponse, NetworkError> {
        let request = Gateway_ListFavoritesRequest()
        return await networkService.perform(factory.listFavorites(request))
    }
    
    // MARK: - User
    
    public func getMe() async -> Result<Gateway_GetMeResponse, NetworkError> {
        let request = Gateway_GetMeRequest()
        return await networkService.perform(factory.getMe(request))
    }
    
    // MARK: - Token Management
    
    public func clearTokens() async {
        await tokenStorage.clearTokens()
    }
    
    public func getAccessToken() async -> String? {
        await tokenStorage.getAccessToken()
    }
}
