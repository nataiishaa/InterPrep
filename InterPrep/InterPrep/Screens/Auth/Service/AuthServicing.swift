import Foundation

public protocol AuthServicing {
    func login(email: String, password: String) async throws
    func register(firstName: String, lastName: String, email: String, password: String) async throws
    func sendPasswordResetCode(email: String) async throws
    func verifyOTP(email: String, code: String) async throws
    func uploadResume() async throws
    func changePassword(email: String, code: String, newPassword: String) async throws
}

#if DEBUG
public final class AuthServiceMock: AuthServicing {
    public init() {}
    public func login(email: String, password: String) async throws {
        try await Task.sleep(nanoseconds: 1_500_000_000)

        if email.contains("@") && password.count >= 8 {
        } else {
            throw AuthError.invalidCredentials
        }
    }

    public func register(firstName: String, lastName: String, email: String, password: String) async throws {
        try await Task.sleep(nanoseconds: 1_500_000_000)

        if email.contains("@") && password.count >= 8 {
        } else {
            throw AuthError.invalidData
        }
    }

    public func sendPasswordResetCode(email: String) async throws {
        try await Task.sleep(nanoseconds: 1_000_000_000)
    }

    public func verifyOTP(email: String, code: String) async throws {
        try await Task.sleep(nanoseconds: 1_000_000_000)

        if code == "1234" {
        } else {
            throw AuthError.invalidOTP
        }
    }

    public func uploadResume() async throws {
        try await Task.sleep(nanoseconds: 2_000_000_000)
    }

    public func changePassword(email: String, code: String, newPassword: String) async throws {
        try await Task.sleep(nanoseconds: 1_000_000_000)
    }
}
#endif

public enum AuthError: LocalizedError {
    case invalidCredentials
    case invalidData
    case invalidOTP
    case networkUnavailable
    case vpnLikely
    case emailAlreadyExists
    case invalidEmail
    case weakPassword

    public var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            return "Неверный email или пароль"
        case .invalidData:
            return "Проверьте правильность введённых данных"
        case .invalidOTP:
            return "Неверный код подтверждения"
        case .networkUnavailable:
            return "Нет интернета. Проверьте подключение и попробуйте снова"
        case .vpnLikely:
            return "Не удалось подключиться к серверу. Возможно, включён VPN — попробуйте отключить его"
        case .emailAlreadyExists:
            return "Пользователь с таким email уже существует"
        case .invalidEmail:
            return "Неверный формат email"
        case .weakPassword:
            return "Пароль слишком простой. Используйте минимум 8 символов, включая буквы и цифры"
        }
    }
}
