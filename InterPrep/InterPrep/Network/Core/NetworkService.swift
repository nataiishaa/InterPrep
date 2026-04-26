import Foundation

@MainActor
public final class NetworkService: ObservableObject {
    public static let shared = NetworkService()
    
    private let grpcClient: GRPCClient
    private let tokenStorage: TokenStorage
    
    public let auth: AuthService
    public let user: UserService
    public let jobs: JobsService
    public let calendar: CalendarService
    
    private init() {
        self.grpcClient = GRPCClient()
        self.tokenStorage = TokenStorage()
        
        self.auth = AuthService(client: grpcClient, tokenStorage: tokenStorage)
        self.user = UserService(client: grpcClient, tokenStorage: tokenStorage)
        self.jobs = JobsService(client: grpcClient, tokenStorage: tokenStorage)
        self.calendar = CalendarService(client: grpcClient, tokenStorage: tokenStorage)
    }
    
    public func configure(host: String = "api.interprep.ru", port: Int = 443) {
    }
}
