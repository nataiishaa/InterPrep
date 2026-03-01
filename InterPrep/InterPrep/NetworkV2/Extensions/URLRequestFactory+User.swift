import Foundation
import SwiftProtobuf

// MARK: - User API Extensions

extension URLRequestFactory {
    // MARK: - Get Me
    
    public func getMe(
        _ message: Gateway_GetMeRequest
    ) -> ProtoRequest<Gateway_GetMeResponse> {
        assemble(
            path: "/gateway.BackendGateway/GetMe",
            message: message
        )
    }
}
