import Foundation
import SwiftProtobuf

extension URLRequestFactory {
    func getMe(
        _ message: User_GetMeRequest
    ) -> ProtoRequest<User_GetMeResponse> {
        assemble(
            path: "/gateway.BackendGateway/GetMe",
            message: message
        )
    }
    
    func getResumeProfile(
        _ message: User_GetResumeProfileRequest
    ) -> ProtoRequest<User_GetResumeProfileResponse> {
        assemble(
            path: "/gateway.BackendGateway/GetResumeProfile",
            message: message
        )
    }
    
    func updateResumeProfile(
        _ message: User_UpdateResumeProfileRequest
    ) -> ProtoRequest<User_UpdateResumeProfileResponse> {
        assemble(
            path: "/gateway.BackendGateway/UpdateResumeProfile",
            message: message
        )
    }
    
    func updateUserProfile(
        _ message: User_UpdateUserProfileRequest
    ) -> ProtoRequest<User_UpdateUserProfileResponse> {
        assemble(
            path: "/gateway.BackendGateway/UpdateUserProfile",
            message: message
        )
    }
    
    func deleteAccount(
        _ message: User_DeleteAccountRequest
    ) -> ProtoRequest<User_DeleteAccountResponse> {
        assemble(
            path: "/gateway.BackendGateway/DeleteAccount",
            message: message
        )
    }
    
    func uploadProfilePhoto(
        _ message: User_UploadProfilePhotoRequest
    ) -> ProtoRequest<User_UploadProfilePhotoResponse> {
        assemble(
            path: "/gateway.BackendGateway/UploadProfilePhoto",
            message: message,
            timeout: 60
        )
    }
}
