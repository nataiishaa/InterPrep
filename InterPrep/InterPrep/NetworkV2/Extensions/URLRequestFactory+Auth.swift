import Foundation
import SwiftProtobuf

// MARK: - Auth API Extensions

extension URLRequestFactory {
    // MARK: - Register
    
    public func register(
        _ message: Gateway_RegisterRequest
    ) -> ProtoRequest<Gateway_RegisterResponse> {
        assemble(
            path: "/gateway.BackendGateway/Register",
            message: message
        )
    }
    
    // MARK: - Login
    
    public func login(
        _ message: Gateway_LoginRequest
    ) -> ProtoRequest<Gateway_LoginResponse> {
        assemble(
            path: "/gateway.BackendGateway/Login",
            message: message
        )
    }
    
    // MARK: - Refresh
    
    public func refresh(
        _ message: Gateway_RefreshRequest
    ) -> ProtoRequest<Gateway_RefreshResponse> {
        assemble(
            path: "/gateway.BackendGateway/Refresh",
            message: message
        )
    }
    
    // MARK: - Password Reset
    
    public func checkPasswordResetEmail(
        _ message: Gateway_PasswordResetCheckEmailRequest
    ) -> ProtoRequest<Gateway_PasswordResetCheckEmailResponse> {
        assemble(
            path: "/gateway.BackendGateway/CheckPasswordResetEmail",
            message: message
        )
    }
    
    public func sendPasswordResetCode(
        _ message: Gateway_PasswordResetSendCodeRequest
    ) -> ProtoRequest<Gateway_PasswordResetSendCodeResponse> {
        assemble(
            path: "/gateway.BackendGateway/SendPasswordResetCode",
            message: message
        )
    }
    
    public func verifyPasswordReset(
        _ message: Gateway_PasswordResetVerifyRequest
    ) -> ProtoRequest<Gateway_PasswordResetVerifyResponse> {
        assemble(
            path: "/gateway.BackendGateway/VerifyPasswordReset",
            message: message
        )
    }
}
