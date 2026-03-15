//
//  ProfilePhotoCache.swift
//  InterPrep
//
//  Кеш фото профиля на диске (по user id). Если фото есть в кеше — не дергаем GetProfilePhoto.
//

import Foundation

public final class ProfilePhotoCache: Sendable {
    public static let shared = ProfilePhotoCache()
    
    private let fileManager = FileManager.default
    private let queue = DispatchQueue(label: "ProfilePhotoCache", qos: .userInitiated)
    
    private var cacheDirectory: URL? {
        fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first?
            .appendingPathComponent("ProfilePhotos", isDirectory: true)
    }
    
    public init() {}
    
    /// Путь к файлу в кеше для данного user id (файл может не существовать).
    public func cacheFileURL(userId: String) -> URL? {
        guard let dir = cacheDirectory else { return nil }
        let safe = userId.filter { $0.isLetter || $0.isNumber }.isEmpty ? "default" : userId.filter { $0.isLetter || $0.isNumber }
        return dir.appendingPathComponent("\(safe).jpg", isDirectory: false)
    }
    
    /// Есть ли фото в кеше для user id.
    public func hasCachedPhoto(userId: String) -> Bool {
        guard let url = cacheFileURL(userId: userId) else { return false }
        return queue.sync { fileManager.fileExists(atPath: url.path) }
    }
    
    /// Загрузить данные фото из кеша. Возвращает nil, если нет в кеше.
    public func loadCachedPhoto(userId: String) -> Data? {
        guard let url = cacheFileURL(userId: userId) else { return nil }
        return queue.sync { try? Data(contentsOf: url) }
    }
    
    /// URL файла в кеше для отображения (если файл есть).
    public func cachedPhotoURL(userId: String) -> URL? {
        guard let url = cacheFileURL(userId: userId), fileManager.fileExists(atPath: url.path) else { return nil }
        return url
    }
    
    /// Сохранить фото в кеш. Создаёт директорию при необходимости.
    public func savePhoto(userId: String, data: Data) {
        queue.async { [weak self] in
            guard let self = self, let dir = self.cacheDirectory, let fileURL = self.cacheFileURL(userId: userId) else { return }
            try? self.fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
            try? data.write(to: fileURL)
        }
    }
    
    /// Сохранить синхронно (для использования до возврата в UI).
    public func savePhotoSync(userId: String, data: Data) {
        guard let dir = cacheDirectory, let fileURL = cacheFileURL(userId: userId) else { return }
        try? fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
        try? data.write(to: fileURL)
    }
    
    /// Удалить фото из кеша для user id.
    public func clearPhoto(userId: String) {
        guard let url = cacheFileURL(userId: userId) else { return }
        queue.async { [weak self] in
            try? self?.fileManager.removeItem(at: url)
        }
    }
}
