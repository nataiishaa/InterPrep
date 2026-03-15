import Foundation
import SwiftProtobuf

extension URLRequestFactory {
    func createEvent(
        _ message: Calendar_CreateEventRequest
    ) -> ProtoRequest<Calendar_CreateEventResponse> {
        assemble(
            path: "/gateway.BackendGateway/CreateEvent",
            message: message
        )
    }
    
    func getEvent(
        _ message: Calendar_GetEventRequest
    ) -> ProtoRequest<Calendar_GetEventResponse> {
        assemble(
            path: "/gateway.BackendGateway/GetEvent",
            message: message
        )
    }
    
    func updateEvent(
        _ message: Calendar_UpdateEventRequest
    ) -> ProtoRequest<Calendar_UpdateEventResponse> {
        assemble(
            path: "/gateway.BackendGateway/UpdateEvent",
            message: message
        )
    }
    
    func deleteEvent(
        _ message: Calendar_DeleteEventRequest
    ) -> ProtoRequest<Calendar_DeleteEventResponse> {
        assemble(
            path: "/gateway.BackendGateway/DeleteEvent",
            message: message
        )
    }
    
    func listEvents(
        _ message: Calendar_ListEventsRequest
    ) -> ProtoRequest<Calendar_ListEventsResponse> {
        assemble(
            path: "/gateway.BackendGateway/ListEvents",
            message: message,
            retryPolicy: RetryPolicy(maxRetries: 3)
        )
    }
    
    func listUpcoming(
        _ message: Calendar_ListUpcomingRequest
    ) -> ProtoRequest<Calendar_ListUpcomingResponse> {
        assemble(
            path: "/gateway.BackendGateway/ListUpcoming",
            message: message,
            retryPolicy: RetryPolicy(maxRetries: 3)
        )
    }
}
