import Foundation
import SwiftProtobuf

// MARK: - Jobs API Extensions

extension URLRequestFactory {
    // MARK: - Search Jobs
    
    public func searchJobs(
        _ message: Gateway_SearchJobsRequest
    ) -> ProtoRequest<Gateway_SearchJobsResponse> {
        assemble(
            path: "/gateway.BackendGateway/SearchJobs",
            message: message
        )
    }
    
    // MARK: - Favorites
    
    public func addFavorite(
        _ message: Gateway_AddFavoriteRequest
    ) -> ProtoRequest<Gateway_AddFavoriteResponse> {
        assemble(
            path: "/gateway.BackendGateway/AddFavorite",
            message: message
        )
    }
    
    public func removeFavorite(
        _ message: Gateway_RemoveFavoriteRequest
    ) -> ProtoRequest<Gateway_RemoveFavoriteResponse> {
        assemble(
            path: "/gateway.BackendGateway/RemoveFavorite",
            message: message
        )
    }
    
    public func listFavorites(
        _ message: Gateway_ListFavoritesRequest
    ) -> ProtoRequest<Gateway_ListFavoritesResponse> {
        assemble(
            path: "/gateway.BackendGateway/ListFavorites",
            message: message
        )
    }
}
