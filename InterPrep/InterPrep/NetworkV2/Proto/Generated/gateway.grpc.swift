// DO NOT EDIT.
// Generated for BackendGateway Register/Login (gRPC client).
// Source: gateway.proto — service BackendGateway
//
// Full client can be regenerated with: cd Proto && ./generate.sh
// (requires protoc-gen-grpc-swift in PATH from grpc-swift 1.23.0)

import Foundation
import GRPC
import NIOCore
import SwiftProtobuf

// MARK: - Client metadata

public enum Gateway_BackendGatewayClientMetadata {
  public static let serviceDescriptor = GRPCServiceDescriptor(
    name: "BackendGateway",
    fullName: "gateway.BackendGateway",
    methods: [
      Gateway_BackendGatewayClientMetadata.Methods.register,
      Gateway_BackendGatewayClientMetadata.Methods.login,
      Gateway_BackendGatewayClientMetadata.Methods.sendPasswordResetCode,
      Gateway_BackendGatewayClientMetadata.Methods.verifyPasswordReset,
      Gateway_BackendGatewayClientMetadata.Methods.getResumeProfile,
      Gateway_BackendGatewayClientMetadata.Methods.searchJobs,
      Gateway_BackendGatewayClientMetadata.Methods.listFavorites,
    ]
  )

  public enum Methods {
    public static let register = GRPCMethodDescriptor(
      name: "Register",
      path: "/gateway.BackendGateway/Register",
      type: GRPCCallType.unary
    )
    public static let login = GRPCMethodDescriptor(
      name: "Login",
      path: "/gateway.BackendGateway/Login",
      type: GRPCCallType.unary
    )
    public static let sendPasswordResetCode = GRPCMethodDescriptor(
      name: "SendPasswordResetCode",
      path: "/gateway.BackendGateway/SendPasswordResetCode",
      type: GRPCCallType.unary
    )
    public static let verifyPasswordReset = GRPCMethodDescriptor(
      name: "VerifyPasswordReset",
      path: "/gateway.BackendGateway/VerifyPasswordReset",
      type: GRPCCallType.unary
    )
    public static let getResumeProfile = GRPCMethodDescriptor(
      name: "GetResumeProfile",
      path: "/gateway.BackendGateway/GetResumeProfile",
      type: GRPCCallType.unary
    )
    public static let searchJobs = GRPCMethodDescriptor(
      name: "SearchJobs",
      path: "/gateway.BackendGateway/SearchJobs",
      type: GRPCCallType.unary
    )
    public static let listFavorites = GRPCMethodDescriptor(
      name: "ListFavorites",
      path: "/gateway.BackendGateway/ListFavorites",
      type: GRPCCallType.unary
    )
  }
}

// MARK: - Client protocol

public protocol Gateway_BackendGatewayClientProtocol: GRPCClient {
  var serviceName: String { get }
  var interceptors: Gateway_BackendGatewayClientInterceptorFactoryProtocol? { get }
  func register(_ request: Auth_RegisterRequest, callOptions: CallOptions?) -> UnaryCall<Auth_RegisterRequest, Auth_RegisterResponse>
  func login(_ request: Auth_LoginRequest, callOptions: CallOptions?) -> UnaryCall<Auth_LoginRequest, Auth_LoginResponse>
  func sendPasswordResetCode(_ request: Auth_PasswordResetSendCodeRequest, callOptions: CallOptions?) -> UnaryCall<Auth_PasswordResetSendCodeRequest, Auth_PasswordResetSendCodeResponse>
  func verifyPasswordReset(_ request: Auth_PasswordResetVerifyRequest, callOptions: CallOptions?) -> UnaryCall<Auth_PasswordResetVerifyRequest, Auth_PasswordResetVerifyResponse>
  func getResumeProfile(_ request: User_GetResumeProfileRequest, callOptions: CallOptions?) -> UnaryCall<User_GetResumeProfileRequest, User_GetResumeProfileResponse>
  func searchJobs(_ request: Jobs_SearchJobsRequest, callOptions: CallOptions?) -> UnaryCall<Jobs_SearchJobsRequest, Jobs_SearchJobsResponse>
  func listFavorites(_ request: Jobs_ListFavoritesRequest, callOptions: CallOptions?) -> UnaryCall<Jobs_ListFavoritesRequest, Jobs_ListFavoritesResponse>
}

extension Gateway_BackendGatewayClientProtocol {
  public var serviceName: String { "gateway.BackendGateway" }

  public func register(
    _ request: Auth_RegisterRequest,
    callOptions: CallOptions? = nil
  ) -> UnaryCall<Auth_RegisterRequest, Auth_RegisterResponse> {
    makeUnaryCall(
      path: Gateway_BackendGatewayClientMetadata.Methods.register.path,
      request: request,
      callOptions: callOptions ?? defaultCallOptions,
      interceptors: interceptors?.makeRegisterInterceptors() ?? []
    )
  }

  public func login(
    _ request: Auth_LoginRequest,
    callOptions: CallOptions? = nil
  ) -> UnaryCall<Auth_LoginRequest, Auth_LoginResponse> {
    makeUnaryCall(
      path: Gateway_BackendGatewayClientMetadata.Methods.login.path,
      request: request,
      callOptions: callOptions ?? defaultCallOptions,
      interceptors: interceptors?.makeLoginInterceptors() ?? []
    )
  }

  public func sendPasswordResetCode(
    _ request: Auth_PasswordResetSendCodeRequest,
    callOptions: CallOptions? = nil
  ) -> UnaryCall<Auth_PasswordResetSendCodeRequest, Auth_PasswordResetSendCodeResponse> {
    makeUnaryCall(
      path: Gateway_BackendGatewayClientMetadata.Methods.sendPasswordResetCode.path,
      request: request,
      callOptions: callOptions ?? defaultCallOptions,
      interceptors: interceptors?.makeSendPasswordResetCodeInterceptors() ?? []
    )
  }

  public func verifyPasswordReset(
    _ request: Auth_PasswordResetVerifyRequest,
    callOptions: CallOptions? = nil
  ) -> UnaryCall<Auth_PasswordResetVerifyRequest, Auth_PasswordResetVerifyResponse> {
    makeUnaryCall(
      path: Gateway_BackendGatewayClientMetadata.Methods.verifyPasswordReset.path,
      request: request,
      callOptions: callOptions ?? defaultCallOptions,
      interceptors: interceptors?.makeVerifyPasswordResetInterceptors() ?? []
    )
  }

  public func getResumeProfile(
    _ request: User_GetResumeProfileRequest,
    callOptions: CallOptions? = nil
  ) -> UnaryCall<User_GetResumeProfileRequest, User_GetResumeProfileResponse> {
    makeUnaryCall(
      path: Gateway_BackendGatewayClientMetadata.Methods.getResumeProfile.path,
      request: request,
      callOptions: callOptions ?? defaultCallOptions,
      interceptors: interceptors?.makeGetResumeProfileInterceptors() ?? []
    )
  }

  public func searchJobs(
    _ request: Jobs_SearchJobsRequest,
    callOptions: CallOptions? = nil
  ) -> UnaryCall<Jobs_SearchJobsRequest, Jobs_SearchJobsResponse> {
    makeUnaryCall(
      path: Gateway_BackendGatewayClientMetadata.Methods.searchJobs.path,
      request: request,
      callOptions: callOptions ?? defaultCallOptions,
      interceptors: interceptors?.makeSearchJobsInterceptors() ?? []
    )
  }

  public func listFavorites(
    _ request: Jobs_ListFavoritesRequest,
    callOptions: CallOptions? = nil
  ) -> UnaryCall<Jobs_ListFavoritesRequest, Jobs_ListFavoritesResponse> {
    makeUnaryCall(
      path: Gateway_BackendGatewayClientMetadata.Methods.listFavorites.path,
      request: request,
      callOptions: callOptions ?? defaultCallOptions,
      interceptors: interceptors?.makeListFavoritesInterceptors() ?? []
    )
  }
}

// MARK: - Interceptor factory

public protocol Gateway_BackendGatewayClientInterceptorFactoryProtocol {
  func makeRegisterInterceptors() -> [ClientInterceptor<Auth_RegisterRequest, Auth_RegisterResponse>]
  func makeLoginInterceptors() -> [ClientInterceptor<Auth_LoginRequest, Auth_LoginResponse>]
  func makeSendPasswordResetCodeInterceptors() -> [ClientInterceptor<Auth_PasswordResetSendCodeRequest, Auth_PasswordResetSendCodeResponse>]
  func makeVerifyPasswordResetInterceptors() -> [ClientInterceptor<Auth_PasswordResetVerifyRequest, Auth_PasswordResetVerifyResponse>]
  func makeGetResumeProfileInterceptors() -> [ClientInterceptor<User_GetResumeProfileRequest, User_GetResumeProfileResponse>]
  func makeSearchJobsInterceptors() -> [ClientInterceptor<Jobs_SearchJobsRequest, Jobs_SearchJobsResponse>]
  func makeListFavoritesInterceptors() -> [ClientInterceptor<Jobs_ListFavoritesRequest, Jobs_ListFavoritesResponse>]
}

// MARK: - Client

public final class Gateway_BackendGatewayClient: Gateway_BackendGatewayClientProtocol {
  public let channel: GRPCChannel
  public var defaultCallOptions: CallOptions
  public var interceptors: Gateway_BackendGatewayClientInterceptorFactoryProtocol?

  public init(
    channel: GRPCChannel,
    defaultCallOptions: CallOptions = CallOptions(),
    interceptors: Gateway_BackendGatewayClientInterceptorFactoryProtocol? = nil
  ) {
    self.channel = channel
    self.defaultCallOptions = defaultCallOptions
    self.interceptors = interceptors
  }
}
