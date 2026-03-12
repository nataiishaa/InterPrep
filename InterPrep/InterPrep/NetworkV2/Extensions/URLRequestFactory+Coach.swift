import Foundation
import SwiftProtobuf

extension URLRequestFactory {
    func ask(
        _ message: Coach_AskRequest
    ) -> ProtoRequest<Coach_AskResponse> {
        assemble(
            path: "/gateway.BackendGateway/Ask",
            message: message
        )
    }
    
    func parseResume(
        _ message: Coach_ParseResumeRequest
    ) -> ProtoRequest<Coach_ParseResumeResponse> {
        assemble(
            path: "/gateway.BackendGateway/ParseResume",
            message: message
        )
    }
    
    func answerResume(
        _ message: Coach_AnswerResumeRequest
    ) -> ProtoRequest<Coach_AnswerResumeResponse> {
        assemble(
            path: "/gateway.BackendGateway/AnswerResume",
            message: message
        )
    }
    
    func getResumeSession(
        _ message: Coach_GetResumeSessionRequest
    ) -> ProtoRequest<Coach_GetResumeSessionResponse> {
        assemble(
            path: "/gateway.BackendGateway/GetResumeSession",
            message: message
        )
    }
}
