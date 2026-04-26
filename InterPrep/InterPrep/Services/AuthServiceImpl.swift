//
//  AuthServiceImpl.swift
//  InterPrep
//
//  Real implementation of AuthService using NetworkServiceV2
//

import AuthFeature
import Foundation
import NetworkService

public final class AuthService: AuthServicing {
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
            if let api = (error as? NetworkError)?.asAPIError {
                if api.code == .alreadyExists { throw AuthError.emailAlreadyExists }
                if api.code == .invalidArgument {
                    let msg = api.serverMessage.lowercased()
                    if msg.contains("email") { throw AuthError.invalidEmail }
                    if msg.contains("password") { throw AuthError.weakPassword }
                }
                throw AuthError.invalidCredentials
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
            if let api = (error as? NetworkError)?.asAPIError {
                if api.code == .alreadyExists { throw AuthError.emailAlreadyExists }
                if api.code == .invalidArgument {
                    let msg = api.serverMessage.lowercased()
                    if msg.contains("email") { throw AuthError.invalidEmail }
                    if msg.contains("password") && msg.contains("8") { throw AuthError.weakPassword }
                }
                throw AuthError.invalidData
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
    }
    
    public func uploadResume() async throws {
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
