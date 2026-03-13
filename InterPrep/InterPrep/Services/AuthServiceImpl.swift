//
//  AuthServiceImpl.swift
//  InterPrep
//
//  Real implementation of AuthService using NetworkServiceV2
//

import Foundation
import NetworkService
import AuthFeature

public final class AuthServiceImpl: AuthService {
    private let networkService: NetworkServiceV2
    
    public init(networkService: NetworkServiceV2 = .shared) {
        self.networkService = networkService
    }
    
    public func login(email: String, password: String) async throws {
        let result = await networkService.login(email: email, password: password)
        
        switch result {
        case .success(let response):
            // Токены уже сохранены в TokenStorage внутри NetworkService
            print("✅ Login successful: \(response)")
        case .failure(let error):
            print("❌ Login failed: \(error)")
            if (error as? NetworkError)?.isConnectionError == true {
                throw AuthError.networkUnavailable
            }
            throw AuthError.invalidCredentials
        }
    }
    
    public func register(firstName: String, lastName: String, email: String, password: String) async throws {
        let result = await networkService.register(
            firstName: firstName,
            lastName: lastName,
            email: email,
            password: password
        )
        
        switch result {
        case .success(let response):
            print("✅ Registration successful: \(response)")
        case .failure(let error):
            print("❌ Registration failed: \(error)")
            if (error as? NetworkError)?.isConnectionError == true {
                throw AuthError.networkUnavailable
            }
            throw AuthError.invalidData
        }
    }
    
    public func sendPasswordResetCode(email: String) async throws {
        let result = await networkService.sendPasswordResetCode(email: email)
        
        switch result {
        case .success:
            print("✅ Password reset code sent")
        case .failure(let error):
            print("❌ Failed to send reset code: \(error)")
            throw error
        }
    }
    
    public func verifyOTP(email: String, code: String) async throws {
        // В API нет отдельного метода для верификации OTP
        // Верификация происходит при смене пароля
        print("✅ OTP will be verified on password change")
    }
    
    public func uploadResume() async throws {
        // TODO: Implement resume upload via NetworkService
        print("⚠️ Resume upload not implemented yet")
    }
    
    public func changePassword(email: String, code: String, newPassword: String) async throws {
        let result = await networkService.verifyPasswordReset(email: email, code: code, password: newPassword)
        
        switch result {
        case .success:
            print("✅ Password changed successfully")
        case .failure(let error):
            print("❌ Password change failed: \(error)")
            throw error
        }
    }
}
