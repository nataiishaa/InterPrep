import Foundation
import SwiftProtobuf

extension URLRequestFactory {
    func register(
        _ message: Auth_RegisterRequest
    ) -> ProtoRequest<Auth_RegisterResponse> {
        assemble(
            path: "/gateway.BackendGateway/Register",
            message: message
        )
    }
    
    func login(
        _ message: Auth_LoginRequest
    ) -> ProtoRequest<Auth_LoginResponse> {
        assemble(
            path: "/gateway.BackendGateway/Login",
            message: message
        )
    }
    
    func refresh(
        _ message: Auth_RefreshRequest
    ) -> ProtoRequest<Auth_RefreshResponse> {
        assemble(
            path: "/gateway.BackendGateway/Refresh",
            message: message
        )
    }
    
    func checkPasswordResetEmail(
        _ message: Auth_PasswordResetCheckEmailRequest
    ) -> ProtoRequest<Auth_PasswordResetCheckEmailResponse> {
        assemble(
            path: "/gateway.BackendGateway/CheckPasswordResetEmail",
            message: message
        )
    }
    
    func sendPasswordResetCode(
        _ message: Auth_PasswordResetSendCodeRequest
    ) -> ProtoRequest<Auth_PasswordResetSendCodeResponse> {
        assemble(
            path: "/gateway.BackendGateway/SendPasswordResetCode",
            message: message
        )
    }
    
    func verifyPasswordReset(
        _ message: Auth_PasswordResetVerifyRequest
    ) -> ProtoRequest<Auth_PasswordResetVerifyResponse> {
        assemble(
            path: "/gateway.BackendGateway/VerifyPasswordReset",
            message: message
        )
    }
}
