//
//  AuthEffectHandler.swift
//  InterPrep
//
//  Effect handler for Auth module
//

import Foundation
import ArchitectureCore

public actor AuthEffectHandler: EffectHandler {
    public typealias S = AuthState
    
    private let authService: AuthService
    
    public init(authService: AuthService) {
        self.authService = authService
    }
    
    public func handle(effect: S.Effect) async -> S.Feedback? {
        switch effect {
        case let .performLogin(email, password):
            do {
                try await authService.login(email: email, password: password)
                return .loginSuccess
            } catch {
                return .loginFailed(error.localizedDescription)
            }
            
        case let .performRegistration(firstName, lastName, email, password):
            do {
                try await authService.register(
                    firstName: firstName,
                    lastName: lastName,
                    email: email,
                    password: password
                )
                return .registrationSuccess
            } catch {
                return .registrationFailed(error.localizedDescription)
            }
            
        case let .sendResetCode(email):
            do {
                try await authService.sendPasswordResetCode(email: email)
                return .resetCodeSent
            } catch {
                return .resetCodeFailed(error.localizedDescription)
            }
            
        case let .verifyOTP(email, code):
            do {
                try await authService.verifyOTP(email: email, code: code)
                return .otpVerified
            } catch {
                return .otpFailed(error.localizedDescription)
            }
            
        case .uploadResume:
            do {
                try await authService.uploadResume()
                return .resumeUploaded
            } catch {
                return .registrationFailed("Не удалось загрузить резюме")
            }
            
        case let .changePassword(email, code, newPassword):
            do {
                try await authService.changePassword(email: email, code: code, newPassword: newPassword)
                return .passwordChanged
            } catch {
                return .loginFailed("Не удалось изменить пароль")
            }
        }
    }
}

// MARK: - Auth Service

public protocol AuthService {
    func login(email: String, password: String) async throws
    func register(firstName: String, lastName: String, email: String, password: String) async throws
    func sendPasswordResetCode(email: String) async throws
    func verifyOTP(email: String, code: String) async throws
    func uploadResume() async throws
    func changePassword(email: String, code: String, newPassword: String) async throws
}

// Mock implementation
public final class AuthServiceMock: AuthService {
    public init() {}
    public func login(email: String, password: String) async throws {
        try await Task.sleep(nanoseconds: 1_500_000_000)
        
        if email.contains("@") && password.count >= 6 {
        } else {
            throw AuthError.invalidCredentials
        }
    }
    
    public func register(firstName: String, lastName: String, email: String, password: String) async throws {
        try await Task.sleep(nanoseconds: 1_500_000_000)
        
        if email.contains("@") && password.count >= 6 {
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

public enum AuthError: LocalizedError {
    case invalidCredentials
    case invalidData
    case invalidOTP
    case networkUnavailable
    
    public var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            return "Неверный email или пароль"
        case .invalidData:
            return "Проверьте правильность введенных данных"
        case .invalidOTP:
            return "Неверный код подтверждения"
        case .networkUnavailable:
            return "Нет соединения с интернетом. Проверьте подключение и попробуйте снова."
        }
    }
}
