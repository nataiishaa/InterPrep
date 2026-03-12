import Foundation
import SwiftProtobuf

extension URLRequestFactory {
    func searchJobs(
        _ message: Jobs_SearchJobsRequest
    ) -> ProtoRequest<Jobs_SearchJobsResponse> {
        assemble(
            path: "/gateway.BackendGateway/SearchJobs",
            message: message
        )
    }
    
    func addFavorite(
        _ message: Jobs_AddFavoriteRequest
    ) -> ProtoRequest<Jobs_AddFavoriteResponse> {
        assemble(
            path: "/gateway.BackendGateway/AddFavorite",
            message: message
        )
    }
    
    func removeFavorite(
        _ message: Jobs_RemoveFavoriteRequest
    ) -> ProtoRequest<Jobs_RemoveFavoriteResponse> {
        assemble(
            path: "/gateway.BackendGateway/RemoveFavorite",
            message: message
        )
    }
    
    func listFavorites(
        _ message: Jobs_ListFavoritesRequest
    ) -> ProtoRequest<Jobs_ListFavoritesResponse> {
        assemble(
            path: "/gateway.BackendGateway/ListFavorites",
            message: message
        )
    }
}
