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
        case .success:
            break
        case .failure(let error):
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
        case .success:
            break
        case .failure(let error):
            
            if (error as? NetworkError)?.isConnectionError == true {
                throw AuthError.networkUnavailable
            }
            
            if case .httpError(let code, let data) = error {
                if let data = data,
                   let errorText = String(data: data, encoding: .utf8) {
                    if errorText.contains("already exists") || errorText.contains("уже существует") {
                        throw AuthError.emailAlreadyExists
                    } else if errorText.contains("invalid email") || errorText.contains("неверный email") {
                        throw AuthError.invalidEmail
                    } else if errorText.contains("password") && errorText.contains("weak") {
                        throw AuthError.weakPassword
                    }
                }
                
                if code == 409 {
                    throw AuthError.emailAlreadyExists
                } else if code == 400 {
                    throw AuthError.invalidData
                }
            }
            
            throw AuthError.invalidData
        }
    }
    
    public func sendPasswordResetCode(email: String) async throws {
        let result = await networkService.sendPasswordResetCode(email: email)
        
        switch result {
        case .success:
            break
        case .failure(let error):
            throw error
        }
    }
    
    public func verifyOTP(email: String, code: String) async throws {
        // В API нет отдельного метода для верификации OTP
        // Верификация происходит при смене пароля
    }
    
    public func uploadResume() async throws {
        // TODO: Implement resume upload via NetworkService
    }
    
    public func changePassword(email: String, code: String, newPassword: String) async throws {
        let result = await networkService.verifyPasswordReset(email: email, code: code, password: newPassword)
        
        switch result {
        case .success:
            break
        case .failure(let error):
            throw error
        }
    }
}
