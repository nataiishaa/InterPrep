//
//  DocumentsState.swift
//  InterPrep
//
//  Documents state management
//

import Foundation
import ArchitectureCore

// MARK: - State

public struct DocumentsState {
    public var folders: [Folder] = []
    public var recentDocuments: [Document] = []
    public var selectedFolder: Folder?
    public var isLoading: Bool = false
    public var error: String?
    public var showingCreateFolderSheet: Bool = false
    public var showingUploadSheet: Bool = false
    
    public init() {}
}

// MARK: - Models

public struct Folder: Identifiable, Equatable, Sendable {
    public let id: UUID
    public var name: String
    public var documentsCount: Int
    public var createdAt: Date
    public var color: FolderColor
    
    public init(
        id: UUID = UUID(),
        name: String,
        documentsCount: Int = 0,
        createdAt: Date = Date(),
        color: FolderColor = .blue
    ) {
        self.id = id
        self.name = name
        self.documentsCount = documentsCount
        self.createdAt = createdAt
        self.color = color
    }
}

public enum FolderColor: String, CaseIterable, Sendable {
    case blue
    case green
    case orange
    case purple
    case red
    case gray
}

public struct Document: Identifiable, Equatable, Sendable {
    public let id: UUID
    public var name: String
    public var type: DocumentType
    public var size: Int64
    public var createdAt: Date
    public var modifiedAt: Date
    public var folderId: UUID?
    public var url: URL?
    
    public init(
        id: UUID = UUID(),
        name: String,
        type: DocumentType,
        size: Int64 = 0,
        createdAt: Date = Date(),
        modifiedAt: Date = Date(),
        folderId: UUID? = nil,
        url: URL? = nil
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.size = size
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
        self.folderId = folderId
        self.url = url
    }
    
    public var formattedSize: String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: size)
    }
}

public enum DocumentType: String, CaseIterable, Sendable {
    case pdf
    case doc
    case docx
    case txt
    case note
    case image
    case other
    
    public var icon: String {
        switch self {
        case .pdf: return "doc.fill"
        case .doc, .docx: return "doc.text.fill"
        case .txt: return "doc.plaintext.fill"
        case .note: return "note.text"
        case .image: return "photo.fill"
        case .other: return "doc"
        }
    }
}

// MARK: - FeatureState

extension DocumentsState: FeatureState {
    public enum Input: Sendable {
        case onAppear
        case folderTapped(Folder)
        case documentTapped(Document)
        case createFolderTapped
        case uploadFileTapped
        case createNoteTapped
        case dismissSheet
        case folderCreated(String)
        case fileUploaded(URL)
        case noteCreated(String, String)
        case documentDeleted(Document)
    }
    
    public enum Feedback: Sendable {
        case foldersLoaded([Folder])
        case recentDocumentsLoaded([Document])
        case loadingFailed(String)
    }
    
    public enum Effect: Sendable {
        case loadFolders
        case loadRecentDocuments
        case createFolder(String)
        case uploadFile(URL)
        case createNote(String, String)
        case deleteDocument(UUID)
        case openDocument(Document)
    }
    
    @MainActor
    public static func reduce(
        state: inout Self,
        with message: Message<Input, Feedback>
    ) -> Effect? {
        switch message {
        case .input(.onAppear):
            state.isLoading = true
            // Note: We can only return one effect, so we'll load folders first
            // The effect handler will chain loading recent documents
            return .loadFolders
            
        case .input(.folderTapped(let folder)):
            state.selectedFolder = folder
            return nil
            
        case .input(.documentTapped(let document)):
            return .openDocument(document)
            
        case .input(.createFolderTapped):
            state.showingCreateFolderSheet = true
            return nil
            
        case .input(.uploadFileTapped):
            state.showingUploadSheet = true
            return nil
            
        case .input(.createNoteTapped):
            state.showingCreateFolderSheet = true
            return nil
            
        case .input(.dismissSheet):
            state.showingCreateFolderSheet = false
            state.showingUploadSheet = false
            return nil
            
        case .input(.folderCreated(let name)):
            state.showingCreateFolderSheet = false
            return .createFolder(name)
            
        case .input(.fileUploaded(let url)):
            state.showingUploadSheet = false
            return .uploadFile(url)
            
        case .input(.noteCreated(let title, let content)):
            state.showingCreateFolderSheet = false
            return .createNote(title, content)
            
        case .input(.documentDeleted(let document)):
            state.recentDocuments.removeAll { $0.id == document.id }
            return .deleteDocument(document.id)
            
        case .feedback(.foldersLoaded(let folders)):
            state.folders = folders
            state.isLoading = false
            return nil
            
        case .feedback(.recentDocumentsLoaded(let documents)):
            state.recentDocuments = documents
            return nil
            
        case .feedback(.loadingFailed(let error)):
            state.isLoading = false
            state.error = error
            return nil
        }
    }
}
