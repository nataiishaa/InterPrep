//
//  DocumentsEffectHandler.swift
//  InterPrep
//
//  Documents effect handler
//

import Foundation
import ArchitectureCore

// MARK: - Effect Handler

public actor DocumentsEffectHandler: EffectHandler {
    public typealias S = DocumentsState
    
    private let documentService: DocumentServiceProtocol
    
    public init(documentService: DocumentServiceProtocol) {
        self.documentService = documentService
    }
    
    public func handle(effect: S.Effect) async -> S.Feedback? {
        switch effect {
        case .loadFolders:
            do {
                let folders = try await documentService.fetchFolders()
                // Also load recent documents after folders
                let documents = try await documentService.fetchRecentDocuments()
                // Note: We can only return one feedback at a time
                // In a real app, you might want to chain these differently
                return .foldersLoaded(folders)
            } catch {
                return .loadingFailed(error.localizedDescription)
            }
            
        case .loadRecentDocuments:
            do {
                let documents = try await documentService.fetchRecentDocuments()
                return .recentDocumentsLoaded(documents)
            } catch {
                return .loadingFailed(error.localizedDescription)
            }
            
        case .createFolder(let name):
            do {
                try await documentService.createFolder(name: name)
                let folders = try await documentService.fetchFolders()
                return .foldersLoaded(folders)
            } catch {
                return .loadingFailed(error.localizedDescription)
            }
            
        case .uploadFile(let url):
            do {
                try await documentService.uploadFile(url: url)
                let documents = try await documentService.fetchRecentDocuments()
                return .recentDocumentsLoaded(documents)
            } catch {
                return .loadingFailed(error.localizedDescription)
            }
            
        case .createNote(let title, let content):
            do {
                try await documentService.createNote(title: title, content: content)
                let documents = try await documentService.fetchRecentDocuments()
                return .recentDocumentsLoaded(documents)
            } catch {
                return .loadingFailed(error.localizedDescription)
            }
            
        case .deleteDocument(let id):
            do {
                try await documentService.deleteDocument(id: id)
                return nil
            } catch {
                return .loadingFailed(error.localizedDescription)
            }
            
        case .openDocument:
            // Navigation handled by coordinator
            return nil
        }
    }
}

// MARK: - Service Protocol

public protocol DocumentServiceProtocol: Actor {
    func fetchFolders() async throws -> [Folder]
    func fetchRecentDocuments() async throws -> [Document]
    func createFolder(name: String) async throws
    func uploadFile(url: URL) async throws
    func createNote(title: String, content: String) async throws
    func deleteDocument(id: UUID) async throws
}

// MARK: - Mock Service

public final actor DocumentServiceMock: DocumentServiceProtocol {
    public init() {}
    
    public func fetchFolders() async throws -> [Folder] {
        try await Task.sleep(nanoseconds: 500_000_000)
        return [
            Folder(name: "Базы данных", documentsCount: 12, color: .blue),
            Folder(name: "Резюме", documentsCount: 5, color: .green),
            Folder(name: "Сопроводительные письма", documentsCount: 8, color: .orange)
        ]
    }
    
    public func fetchRecentDocuments() async throws -> [Document] {
        try await Task.sleep(nanoseconds: 500_000_000)
        return [
            Document(
                name: "Резюме iOS Developer.pdf",
                type: .pdf,
                size: 245_760,
                createdAt: Date().addingTimeInterval(-86400)
            ),
            Document(
                name: "Заметки по интервью.txt",
                type: .note,
                size: 12_288,
                createdAt: Date().addingTimeInterval(-172800)
            ),
            Document(
                name: "Портфолио проектов.pdf",
                type: .pdf,
                size: 1_048_576,
                createdAt: Date().addingTimeInterval(-259200)
            )
        ]
    }
    
    public func createFolder(name: String) async throws {
        try await Task.sleep(nanoseconds: 500_000_000)
    }
    
    public func uploadFile(url: URL) async throws {
        try await Task.sleep(nanoseconds: 1_000_000_000)
    }
    
    public func createNote(title: String, content: String) async throws {
        try await Task.sleep(nanoseconds: 500_000_000)
    }
    
    public func deleteDocument(id: UUID) async throws {
        try await Task.sleep(nanoseconds: 300_000_000)
    }
}
