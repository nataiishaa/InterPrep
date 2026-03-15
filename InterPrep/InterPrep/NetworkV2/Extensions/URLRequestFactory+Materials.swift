import Foundation
import SwiftProtobuf

extension URLRequestFactory {
    func uploadFile(
        _ message: Materials_UploadFileRequest
    ) -> ProtoRequest<Materials_UploadFileResponse> {
        assemble(
            path: "/gateway.BackendGateway/UploadFile",
            message: message,
            retryPolicy: RetryPolicy(maxRetries: 2)
        )
    }
    
    func downloadFile(
        _ message: Materials_DownloadFileRequest
    ) -> ProtoRequest<Materials_DownloadFileResponse> {
        assemble(
            path: "/gateway.BackendGateway/DownloadFile",
            message: message
        )
    }
    
    func listFolder(
        _ message: Materials_ListFolderRequest
    ) -> ProtoRequest<Materials_ListFolderResponse> {
        assemble(
            path: "/gateway.BackendGateway/ListFolder",
            message: message
        )
    }
    
    func createFolder(
        _ message: Materials_CreateFolderRequest
    ) -> ProtoRequest<Materials_CreateFolderResponse> {
        assemble(
            path: "/gateway.BackendGateway/CreateFolder",
            message: message
        )
    }
    
    func createLink(
        _ message: Materials_CreateLinkRequest
    ) -> ProtoRequest<Materials_CreateLinkResponse> {
        assemble(
            path: "/gateway.BackendGateway/CreateLink",
            message: message
        )
    }
    
    func renameNode(
        _ message: Materials_RenameNodeRequest
    ) -> ProtoRequest<Materials_RenameNodeResponse> {
        assemble(
            path: "/gateway.BackendGateway/RenameNode",
            message: message,
            retryPolicy: RetryPolicy(maxRetries: 3)
        )
    }
    
    func deleteNode(
        _ message: Materials_DeleteNodeRequest
    ) -> ProtoRequest<Materials_DeleteNodeResponse> {
        assemble(
            path: "/gateway.BackendGateway/DeleteNode",
            message: message,
            retryPolicy: RetryPolicy(maxRetries: 3)
        )
    }
}
