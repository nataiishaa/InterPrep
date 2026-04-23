import Foundation
import SwiftProtobuf

// MARK: - HTTP Method

public enum HTTPMethod: String, Sendable {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
    case patch = "PATCH"
}

// MARK: - HTTP Header

public struct HTTPHeader: Sendable {
    public let name: String
    public let value: String
    
    public init(name: String, value: String) {
        self.name = name
        self.value = value
    }
    
    public static func authorization(_ token: String) -> HTTPHeader {
        HTTPHeader(name: "Authorization", value: "Bearer \(token)")
    }
    
    public static func contentType(_ type: ContentType) -> HTTPHeader {
        HTTPHeader(name: "Content-Type", value: type.rawValue)
    }
}

// MARK: - Content Type

public enum ContentType: String, Sendable {
    case protobuf = "application/x-protobuf"
    case json = "application/json"
}

// MARK: - Retry Policy

public struct RetryPolicy: Sendable {
    public let maxRetries: Int
    public var currentRetry: Int
    
    public init(maxRetries: Int) {
        self.maxRetries = maxRetries
        self.currentRetry = 0
    }
    
    public var shouldRetry: Bool {
        currentRetry < maxRetries
    }
    
    public mutating func incrementRetry() {
        currentRetry += 1
    }
}

// MARK: - Proto Request

public struct ProtoRequest<Response: Message>: Sendable {
    public typealias DecodingStrategy = (Data) async throws -> Response
    public typealias EncodingStrategy = (any Message) async throws -> Data
    
    public let urlComponents: URLComponents
    public let messageToEncode: (any Message)?
    public let decodingStrategy: DecodingStrategy
    public let encodingStrategy: EncodingStrategy
    public let method: HTTPMethod
    public let headers: [HTTPHeader]
    public let cachePolicy: URLRequest.CachePolicy
    public let timeout: TimeInterval
    public var retryPolicy: RetryPolicy?
    public var token: String?
    
    init(
        urlComponents: URLComponents,
        messageToEncode: (any Message)?,
        decodingStrategy: @escaping DecodingStrategy,
        encodingStrategy: @escaping EncodingStrategy,
        method: HTTPMethod,
        headers: [HTTPHeader],
        cachePolicy: URLRequest.CachePolicy,
        timeout: TimeInterval,
        retryPolicy: RetryPolicy?
    ) {
        self.urlComponents = urlComponents
        self.messageToEncode = messageToEncode
        self.decodingStrategy = decodingStrategy
        self.encodingStrategy = encodingStrategy
        self.method = method
        self.headers = headers
        self.cachePolicy = cachePolicy
        self.timeout = timeout
        self.retryPolicy = retryPolicy
    }
    
    // MARK: - Authorization
    
    public func authorized(with token: String) -> Self {
        var copy = self
        copy.token = token
        return copy
    }
    
    public func deauthorized() -> Self {
        var copy = self
        copy.token = nil
        return copy
    }
    
    // MARK: - Retry
    
    public var shouldRetry: Bool {
        retryPolicy?.shouldRetry ?? false
    }
    
    public func withReducedRetries() -> Self {
        var copy = self
        if var policy = copy.retryPolicy {
            policy.incrementRetry()
            copy.retryPolicy = policy
        }
        return copy
    }
    
    // MARK: - URLRequest Conversion
    
    public func makeURLRequest() async throws -> URLRequest {
        guard let url = urlComponents.url else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.cachePolicy = cachePolicy
        request.timeoutInterval = timeout
        
        request.setValue("InterPrep/1.0 (iOS)", forHTTPHeaderField: "User-Agent")
        
        for header in headers {
            request.setValue(header.value, forHTTPHeaderField: header.name)
        }
        
        if let token = token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        // После цикла: иначе Content-Type из фабрики остаётся последним и перезаписывает protobuf
        request.setValue("application/x-protobuf", forHTTPHeaderField: "Content-Type")
        request.setValue("application/x-protobuf", forHTTPHeaderField: "Accept")
        
        if let message = messageToEncode {
            request.httpBody = try await encodingStrategy(message)
        }
        
        return request
    }
}

// MARK: - Network Error

public enum NetworkError: Error, LocalizedError {
    case invalidURL
    case encodingFailed(Error)
    case decodingFailed(Error)
    case httpError(Int, Data?)
    case apiError(APIError)
    case unauthorized
    case noData
    case transportError(Error)
    case unknown
    
    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .encodingFailed(let error):
            return "Encoding failed: \(error.localizedDescription)"
        case .decodingFailed(let error):
            return "Decoding failed: \(error.localizedDescription)"
        case .httpError(let code, _):
            return "HTTP error: \(code)"
        case .apiError(let apiError):
            return apiError.userMessage
        case .unauthorized:
            return "Unauthorized"
        case .noData:
            return "No data received"
        case .transportError(let error):
            return (error as NSError).localizedDescription
        case .unknown:
            return "Unknown error"
        }
    }
    
    /// True if this is a connection/transport failure (e.g. connection lost, timeout, no network).
    public var isConnectionError: Bool {
        if case .transportError(let error) = self {
            let ns = error as NSError
            return ns.domain == NSURLErrorDomain && (
                ns.code == NSURLErrorNotConnectedToInternet ||
                ns.code == NSURLErrorNetworkConnectionLost ||
                ns.code == NSURLErrorTimedOut ||
                ns.code == NSURLErrorCannotConnectToHost
            )
        }
        return false
    }
}

// MARK: - API Error Code (gRPC status codes used by backend)

public enum APIErrorCode: String, Sendable {
    case unauthenticated = "Unauthenticated"
    case invalidArgument = "InvalidArgument"
    case notFound = "NotFound"
    case alreadyExists = "AlreadyExists"
    case permissionDenied = "PermissionDenied"
    case internalError = "Internal"
    case resourceExhausted = "ResourceExhausted"
    case failedPrecondition = "FailedPrecondition"
    case unknown = "Unknown"
}

// MARK: - API Error

/// Ошибка API с кодом и сообщением сервера. Соответствует каталогу gRPC-ошибок api-gateway.
public struct APIError: Error, LocalizedError, Sendable {
    public let code: APIErrorCode
    /// Сообщение от сервера (англ., как в каталоге).
    public let serverMessage: String

    public init(code: APIErrorCode, serverMessage: String = "") {
        self.code = code
        self.serverMessage = serverMessage
    }

    /// Пользовательское сообщение для показа в UI (по коду и известным serverMessage).
    public var userMessage: String {
        let msg = serverMessage.lowercased()
        switch code {
        case .unauthenticated:
            if msg.contains("missing metadata") || msg.contains("missing authorization") || msg.contains("invalid authorization format") {
                return "Войдите в аккаунт"
            }
            if msg.contains("invalid token") || msg.contains("invalid token claims") || msg.contains("invalid user id in token") {
                return "Сессия истекла. Войдите снова"
            }
            if msg.contains("invalid credentials") {
                return "Неверный email или пароль"
            }
            if msg.contains("invalid refresh token") {
                return "Сессия истекла. Войдите снова"
            }
            if msg.contains("user not found in context") {
                return "Войдите в аккаунт"
            }
            return "Требуется авторизация"

        case .invalidArgument:
            if msg.contains("email is required") { return "Введите email" }
            if msg.contains("password must be at least 8 characters") { return "Пароль не менее 8 символов" }
            if msg.contains("password is required") { return "Введите пароль" }
            if msg.contains("code is required") { return "Введите код" }
            if msg.contains("new_password is required") { return "Введите новый пароль" }
            if msg.contains("invalid email format") { return "Неверный формат email" }
            if msg.contains("invalid code format") { return "Неверный формат кода" }
            if msg.contains("invalid code") || msg.contains("code expired or used") { return "Неверный или просроченный код" }
            if msg.contains("file_content is required") { return "Выберите файл" }
            if msg.contains("file too large") { return "Файл слишком большой" }
            if msg.contains("filename is required") { return "Укажите имя файла" }
            if msg.contains("name is required") { return "Укажите название" }
            if msg.contains("url is required") { return "Укажите ссылку" }
            if msg.contains("node_id is required") { return "Укажите элемент" }
            if msg.contains("new_name is required") { return "Укажите новое имя" }
            if msg.contains("question is required") { return "Введите вопрос" }
            if msg.contains("session_id is required") || msg.contains("session_id must be a valid uuid") { return "Неверный идентификатор сессии" }
            if msg.contains("vacancy_id is required") { return "Укажите вакансию" }
            if msg.contains("material_id is required") { return "Укажите материал" }
            if msg.contains("material is not a file") { return "Это не файл" }
            if msg.contains("profile required") { return "Заполните профиль" }
            if msg.contains("event is required") { return "Укажите событие" }
            if msg.contains("start_time is required") { return "Укажите время начала" }
            if msg.contains("end_time is required") { return "Укажите время окончания" }
            if msg.contains("title is required") { return "Укажите название" }
            if msg.contains("start_time must be before end_time") { return "Время начала должно быть раньше окончания" }
            if msg.contains("patch is required") { return "Укажите изменения" }
            if msg.contains("title cannot be empty") { return "Название не может быть пустым" }
            if msg.contains("from_time and to_time are required") { return "Укажите период" }
            if msg.contains("from_time must be before to_time") { return "Начало периода должно быть раньше конца" }
            if msg.contains("time range cannot exceed 1 year") { return "Период не более года" }
            return "Проверьте введённые данные"

        case .notFound:
            if msg.contains("user not found") { return "Пользователь не найден" }
            if msg.contains("event not found") { return "Событие не найдено" }
            if msg.contains("resume profile not found") { return "Профиль резюме не найден" }
            if msg.contains("resume file not found") { return "Файл резюме не найден" }
            if msg.contains("profile photo not set") { return "Фото не задано" }
            if msg.contains("file not found") { return "Файл не найден" }
            if msg.contains("session not found") { return "Сессия не найдена" }
            return "Не найдено"

        case .alreadyExists:
            if msg.contains("user with this email already exists") || msg.contains("user with this email or username already exists") {
                return "Пользователь с таким email уже существует"
            }
            if msg.contains("email already taken") { return "Этот email уже занят" }
            return "Уже существует"

        case .permissionDenied:
            if msg.contains("invalid password") { return "Неверный пароль" }
            if msg.contains("invalid or expired code") || msg.contains("invalid code") { return "Неверный или просроченный код" }
            if msg.contains("access denied") { return "Нет доступа" }
            return "Доступ запрещён"

        case .resourceExhausted:
            if msg.contains("please wait before requesting another code") { return "Подождите перед повторной отправкой кода" }
            if msg.contains("too many attempts") { return "Слишком много попыток. Подождите" }
            return "Превышен лимит. Попробуйте позже"

        case .failedPrecondition:
            if msg.contains("resume profile not available") { return "Загрузите резюме" }
            if msg.contains("resume profile incomplete") { return "Заполните профиль резюме" }
            return "Выполните требуемые условия"

        case .internalError:
            if msg.contains("database error") { return "Ошибка сервера. Попробуйте позже" }
            if msg.contains("failed to hash password") { return "Ошибка сервера. Попробуйте позже" }
            if msg.contains("failed to create user") { return "Ошибка регистрации. Попробуйте позже" }
            if msg.contains("failed to generate token") { return "Ошибка авторизации. Попробуйте позже" }
            if msg.contains("failed to create refresh token") { return "Ошибка авторизации. Попробуйте позже" }
            if msg.contains("user not found") { return "Ошибка сервера. Попробуйте позже" }
            if msg.contains("materials client not configured") { return "Сервис временно недоступен" }
            if msg.contains("failed to upload") || msg.contains("failed to save") { return "Не удалось загрузить. Попробуйте позже" }
            if msg.contains("failed to load") { return "Не удалось загрузить данные" }
            return "Ошибка сервера. Попробуйте позже"

        case .unknown:
            return "Произошла ошибка"
        }
    }

    public var errorDescription: String? {
        userMessage
    }
}

// MARK: - Parse from HTTP (status code + optional body)

extension APIError {
    /// Парсит ошибку из HTTP-ответа (статус + тело). Для запросов через URLSession/AsyncNetworkService.
    public static func from(httpStatusCode: Int, body: Data?) -> APIError {
        let message: String
        if let data = body,
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let msg = (json["message"] as? String) ?? (json["error"] as? String) ?? (json["details"] as? String) {
            message = msg
        } else if let data = body {
            message = String(data: data, encoding: .utf8) ?? ""
        } else {
            message = ""
        }
        let msg = message.lowercased()

        let code: APIErrorCode
        switch httpStatusCode {
        case 401: code = .unauthenticated
        case 403: code = .permissionDenied
        case 404: code = .notFound
        case 409: code = .alreadyExists
        case 429: code = .resourceExhausted
        case 400, 412:
            code = msg.contains("resume profile") ? .failedPrecondition : .invalidArgument
        default:
            code = (400...499).contains(httpStatusCode) ? .invalidArgument : .internalError
        }

        return APIError(code: code, serverMessage: message.isEmpty ? "" : message)
    }
}

// MARK: - NetworkError integration

extension NetworkError {
    /// Если ошибка — HTTP или уже API, возвращает APIError для показа пользователю.
    public var asAPIError: APIError? {
        switch self {
        case .unauthorized:
            return APIError(code: .unauthenticated, serverMessage: "missing authorization header")
        case .httpError(let statusCode, let data):
            return APIError.from(httpStatusCode: statusCode, body: data)
        case .apiError(let apiError):
            return apiError
        case .invalidURL, .encodingFailed, .decodingFailed, .noData, .transportError, .unknown:
            return nil
        }
    }
}
