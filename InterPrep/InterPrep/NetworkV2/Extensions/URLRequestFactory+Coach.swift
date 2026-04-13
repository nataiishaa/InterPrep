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
    
    func uploadAndParseResume(
        _ message: Coach_UploadAndParseResumeRequest
    ) -> ProtoRequest<Coach_UploadAndParseResumeResponse> {
        assemble(
            path: "/gateway.BackendGateway/UploadAndParseResume",
            message: message,
            timeout: 120
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
    
    func prepareForVacancy(
        _ message: Coach_PrepareForVacancyRequest
    ) -> ProtoRequest<Coach_PrepareForVacancyResponse> {
        assemble(
            path: "/gateway.BackendGateway/PrepareForVacancy",
            message: message,
            timeout: 120,
            retryPolicy: RetryPolicy(maxRetries: 1)
        )
    }
    
    func reviewResume(
        _ message: Coach_ReviewResumeRequest
    ) -> ProtoRequest<Coach_ReviewResumeResponse> {
        assemble(
            path: "/gateway.BackendGateway/ReviewResume",
            message: message,
            timeout: 120,
            retryPolicy: RetryPolicy(maxRetries: 1)
        )
    }
    
    func clearChatHistory(
        _ message: Coach_ClearChatHistoryRequest
    ) -> ProtoRequest<Coach_ClearChatHistoryResponse> {
        assemble(
            path: "/gateway.BackendGateway/ClearChatHistory",
            message: message
        )
    }
    
    func getCoachChatHistory(
        _ message: Coach_GetCoachChatHistoryRequest
    ) -> ProtoRequest<Coach_GetCoachChatHistoryResponse> {
        assemble(
            path: "/gateway.BackendGateway/GetCoachChatHistory",
            message: message
        )
    }
}
