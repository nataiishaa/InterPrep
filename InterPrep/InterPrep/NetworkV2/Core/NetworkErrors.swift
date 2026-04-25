import Foundation
import GRPC

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
    
    /// True when failure is likely due to no connectivity, DNS, TLS handshake, or server unreachable.
    public var isConnectionError: Bool {
        if case .transportError(let error) = self {
            return Self.isTransportLikelyConnectionFailure(error)
        }
        return false
    }

    /// Shared so call sites (e.g. chat) can classify underlying transport errors without wrapping in `NetworkError`.
    public static func isTransportLikelyConnectionFailure(_ error: Error) -> Bool {
        if let status = error as? GRPCStatus {
            switch status.code {
            case .unavailable, .deadlineExceeded, .cancelled:
                return true
            case .unknown, .aborted:
                let m = (status.message ?? "").lowercased()
                if m.contains("connection") || m.contains("network") || m.contains("reset") || m.contains("refused") {
                    return true
                }
                return false
            default:
                break
            }
        }
        let ns = error as NSError
        if ns.domain == NSURLErrorDomain {
            switch ns.code {
            case NSURLErrorNotConnectedToInternet,
                 NSURLErrorNetworkConnectionLost,
                 NSURLErrorTimedOut,
                 NSURLErrorCannotConnectToHost,
                 NSURLErrorCannotFindHost,
                 NSURLErrorDNSLookupFailed,
                 NSURLErrorSecureConnectionFailed,
                 NSURLErrorServerCertificateUntrusted,
                 NSURLErrorCannotLoadFromNetwork,
                 NSURLErrorInternationalRoamingOff,
                 NSURLErrorDataNotAllowed:
                return true
            default:
                break
            }
        }
        if ns.domain == NSPOSIXErrorDomain {
            // ECONNREFUSED, ENETUNREACH, EHOSTUNREACH, EPIPE (typical on Apple platforms)
            if [32, 50, 51, 54, 61, 64, 65].contains(ns.code) { return true }
        }
        let low = ns.localizedDescription.lowercased()
        if low.contains("connection refused")
            || low.contains("connection reset")
            || low.contains("network is unreachable")
            || low.contains("could not connect")
            || low.contains("broken pipe") {
            return true
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

public struct APIError: Error, LocalizedError, Sendable {
    public let code: APIErrorCode
    public let serverMessage: String

    public init(code: APIErrorCode, serverMessage: String = "") {
        self.code = code
        self.serverMessage = serverMessage
    }

    // swiftlint:disable:next cyclomatic_complexity function_body_length
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

// MARK: - Parse from HTTP status (backward compat for .httpError case)

extension APIError {
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

// MARK: - NetworkError → APIError

extension NetworkError {
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
