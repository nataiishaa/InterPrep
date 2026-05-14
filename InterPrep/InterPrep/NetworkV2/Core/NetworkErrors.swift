import Foundation
import GRPC

public enum NetworkError: Error, LocalizedError {
    case invalidURL
    case encodingFailed(Error)
    case decodingFailed(Error)
    case httpError(Int, Data?)
    case apiError(APIError)
    case unauthorized
    case noData
    case transportError(Error)
    case timeout(vpnLikely: Bool)
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
            let desc = String(describing: error).lowercased()
            if desc.contains("413") || desc.contains("payload too large") || desc.contains("request entity too large") {
                return "Файл слишком большой. Максимальный размер — 25 МБ"
            }
            return (error as NSError).localizedDescription
        case .timeout(let vpnLikely):
            if vpnLikely {
                return "Не удалось подключиться к серверу. Возможно, включён VPN — попробуйте отключить его"
            }
            return "Нет интернета. Проверьте подключение и попробуйте снова"
        case .unknown:
            return "Unknown error"
        }
    }

    public var isTimeoutError: Bool {
        if case .timeout = self { return true }
        return false
    }

    public var isConnectionError: Bool {
        if case .timeout = self { return true }
        if case .transportError(let error) = self {
            return Self.isTransportLikelyConnectionFailure(error)
        }
        return false
    }

    public static func isTransportLikelyConnectionFailure(_ error: Error) -> Bool {
        if let status = error as? GRPCStatus {
            switch status.code {
            case .unavailable, .deadlineExceeded, .cancelled:
                return true
            case .unknown, .aborted:
                let msg = (status.message ?? "").lowercased()
                if msg.contains("connection") || msg.contains("network") || msg.contains("reset") || msg.contains("refused") {
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
            if [32, 50, 51, 54, 61, 64, 65].contains(ns.code) { return true }
        }
        let low = String(describing: error).lowercased()
        if low.contains("connection refused")
            || low.contains("connection reset")
            || low.contains("connection interrupted")
            || low.contains("network is unreachable")
            || low.contains("could not connect")
            || low.contains("broken pipe")
            || low.contains("surfaceclientfailed")
            || low.contains("client_internal_error")
            || low.contains("stream reset") {
            return true
        }
        return false
    }
}

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

public struct APIError: Error, LocalizedError, Sendable {
    public let code: APIErrorCode
    public let serverMessage: String

    public init(code: APIErrorCode, serverMessage: String = "") {
        self.code = code
        self.serverMessage = serverMessage
    }

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
            if msg.contains("user not found in context") || msg.contains("user id not found in context") {
                return "Войдите в аккаунт"
            }
            if msg.contains("missing user id") {
                return "Войдите в аккаунт"
            }
            if msg.contains("invalid internal api key") {
                return "Ошибка авторизации. Попробуйте позже"
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
            if msg.contains("invalid user id") { return "Ошибка авторизации" }
            if msg.contains("user_id required") { return "Ошибка авторизации" }
            if msg.contains("file_content is required") { return "Выберите файл" }
            if msg.contains("file too large") { return "Файл слишком большой (максимум 20 МБ)" }
            if msg.contains("filename is required") { return "Укажите имя файла" }
            if msg.contains("filename is too long") { return "Имя файла слишком длинное (максимум 120 символов)" }
            if msg.contains("unsupported file extension") { return "Неподдерживаемый формат файла" }
            if msg.contains("file content does not match") { return "Содержимое файла не соответствует расширению" }
            if msg.contains("mime_type does not match") { return "Тип файла не соответствует расширению" }
            if msg.contains("mime_type is required") { return "Укажите тип файла" }
            if msg.contains("unsupported image type") { return "Неподдерживаемый формат изображения. Используйте JPEG, PNG или WebP" }
            if msg.contains("name is required") { return "Укажите название" }
            if msg.contains("name is too long") { return "Название слишком длинное (максимум 120 символов)" }
            if msg.contains("name contains forbidden characters") { return "Название содержит недопустимые символы" }
            if msg.contains("url is required") { return "Укажите ссылку" }
            if msg.contains("node_id is required") { return "Укажите элемент" }
            if msg.contains("new_name is required") { return "Укажите новое имя" }
            if msg.contains("material_id is required") { return "Укажите материал" }
            if msg.contains("material is not a file") { return "Это не файл" }
            if msg.contains("question is required") { return "Введите вопрос" }
            if msg.contains("question is too long") { return "Вопрос слишком длинный (максимум 2000 символов)" }
            if msg.contains("question contains unsupported control characters") { return "Вопрос содержит недопустимые символы" }
            if msg.contains("too many context chunks") { return "Слишком много элементов контекста" }
            if msg.contains("context chunk content is too long") { return "Элемент контекста слишком длинный" }
            if msg.contains("context chunk content is required") { return "Элемент контекста не может быть пустым" }
            if msg.contains("context chunk contains unsupported control characters") { return "Контекст содержит недопустимые символы" }
            if msg.contains("content is too long") { return "Сообщение слишком длинное (максимум 4000 символов)" }
            if msg.contains("content is required") { return "Введите сообщение" }
            if msg.contains("content contains unsupported control characters") { return "Сообщение содержит недопустимые символы" }
            if msg.contains("owner must be user or assistant") { return "Ошибка отправки сообщения" }
            if msg.contains("session_id is required") || msg.contains("session_id must be a valid uuid") { return "Неверный идентификатор сессии" }
            if msg.contains("vacancy_id is required") { return "Укажите вакансию" }
            if msg.contains("vacancy_id must be numeric") { return "Неверный формат вакансии" }
            if msg.contains("page must be >= 0") { return "Неверный номер страницы" }
            if msg.contains("per_page must be between") { return "Неверное количество элементов на странице" }
            if msg.contains("profile required") { return "Заполните профиль" }
            if msg.contains(".doc format is not supported") || msg.contains("legacy doc format") { return "Формат .doc не поддерживается. Сохраните файл как .docx или .pdf" }
            if msg.contains("failed to extract text") { return "Не удалось извлечь текст из файла" }
            if msg.contains("event is required") { return "Укажите событие" }
            if msg.contains("start_time is required") { return "Укажите время начала" }
            if msg.contains("end_time is required") { return "Укажите время окончания" }
            if msg.contains("title is required") || msg.contains("title cannot be empty") { return "Укажите название" }
            if msg.contains("title is too long") { return "Название слишком длинное (максимум 200 символов)" }
            if msg.contains("description is too long") { return "Описание слишком длинное (максимум 5000 символов)" }
            if msg.contains("location is too long") { return "Место слишком длинное (максимум 255 символов)" }
            if msg.contains("invalid timezone") { return "Неверный формат часового пояса" }
            if msg.contains("start_time must be before end_time") { return "Время начала должно быть раньше окончания" }
            if msg.contains("patch is required") { return "Укажите изменения" }
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
            if msg.contains("vacancy not found") { return "Вакансия не найдена" }
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
            if msg.contains("unauthorized") { return "Нет доступа" }
            return "Доступ запрещён"

        case .resourceExhausted:
            if msg.contains("please wait before requesting another code") { return "Подождите перед повторной отправкой кода" }
            if msg.contains("too many attempts") { return "Слишком много попыток. Подождите" }
            if msg.contains("user storage limit exceeded") { return "Превышен лимит хранилища (максимум 25 МБ)" }
            return "Превышен лимит. Попробуйте позже"

        case .failedPrecondition:
            if msg.contains("resume profile not available") { return "Загрузите резюме" }
            if msg.contains("resume profile incomplete") { return "Заполните профиль резюме" }
            if msg.contains("resume is not uploaded") { return "Резюме не загружено. Загрузите резюме в разделе «Профиль»" }
            return "Выполните требуемые условия"

        case .internalError:
            if msg.contains("resume") { return "Профиль резюме не найден" }
            if msg.contains("database error") { return "Ошибка сервера. Попробуйте позже" }
            if msg.contains("failed to hash password") { return "Ошибка сервера. Попробуйте позже" }
            if msg.contains("failed to create user") { return "Ошибка регистрации. Попробуйте позже" }
            if msg.contains("failed to generate token") { return "Ошибка авторизации. Попробуйте позже" }
            if msg.contains("failed to create refresh token") { return "Ошибка авторизации. Попробуйте позже" }
            if msg.contains("user not found") { return "Ошибка сервера. Попробуйте позже" }
            if msg.contains("materials client not configured") { return "Сервис временно недоступен" }
            if msg.contains("failed to send email") { return "Не удалось отправить письмо. Попробуйте позже" }
            if msg.contains("failed to upload") || msg.contains("failed to save") { return "Не удалось загрузить. Попробуйте позже" }
            if msg.contains("failed to load") || msg.contains("failed to read") { return "Не удалось загрузить данные" }
            if msg.contains("failed to update password") || msg.contains("failed to mark code") || msg.contains("failed to invalidate") {
                return "Не удалось сменить пароль. Попробуйте позже"
            }
            if msg.contains("failed to begin transaction") || msg.contains("failed to commit transaction") {
                return "Ошибка сервера. Попробуйте позже"
            }
            if msg.contains("failed to mark user as deleted") || msg.contains("failed to revoke refresh tokens") {
                return "Не удалось удалить аккаунт. Попробуйте позже"
            }
            if msg.contains("failed to validate user storage") { return "Не удалось проверить хранилище. Попробуйте позже" }
            if msg.contains("failed to create") { return "Не удалось создать. Попробуйте позже" }
            if msg.contains("failed to update") { return "Не удалось обновить. Попробуйте позже" }
            if msg.contains("failed to delete") { return "Не удалось удалить. Попробуйте позже" }
            if msg.contains("failed to rename") { return "Не удалось переименовать. Попробуйте позже" }
            if msg.contains("failed to search") { return "Не удалось выполнить поиск. Попробуйте позже" }
            if msg.contains("failed to get") || msg.contains("failed to list") { return "Не удалось загрузить данные" }
            if msg.contains("failed to process") { return "Не удалось обработать запрос. Попробуйте позже" }
            if msg.contains("failed to parse") { return "Не удалось обработать файл. Попробуйте позже" }
            if msg.contains("failed to add") || msg.contains("failed to remove") { return "Не удалось выполнить операцию. Попробуйте позже" }
            if msg.contains("failed to generate") || msg.contains("failed to save") || msg.contains("failed to check") || msg.contains("failed to increment") {
                return "Ошибка сервера. Попробуйте позже"
            }
            if msg.contains("upsert resume profile") || msg.contains("patch resume profile") {
                return "Не удалось обновить профиль резюме. Попробуйте позже"
            }
            return "Ошибка сервера. Попробуйте позже"

        case .unknown:
            return "Произошла ошибка"
        }
    }

    public var errorDescription: String? {
        userMessage
    }
}

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

extension NetworkError {
    public var asAPIError: APIError? {
        switch self {
        case .unauthorized:
            return APIError(code: .unauthenticated, serverMessage: "missing authorization header")
        case .httpError(let statusCode, let data):
            return APIError.from(httpStatusCode: statusCode, body: data)
        case .apiError(let apiError):
            return apiError
        case .invalidURL, .encodingFailed, .decodingFailed, .noData, .transportError, .timeout, .unknown:
            return nil
        }
    }
}
