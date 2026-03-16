import Foundation
import SwiftProtobuf

extension URLRequestFactory {
    /// LLM-запросы могут занимать до 60–120 с; таймаут 120 с. При обрыве соединения (-1005) — один повтор.
    func ask(
        _ message: Coach_AskRequest
    ) -> ProtoRequest<Coach_AskResponse> {
        assemble(
            path: "/gateway.BackendGateway/Ask",
            message: message,
            timeout: 120,
            retryPolicy: RetryPolicy(maxRetries: 1)
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
