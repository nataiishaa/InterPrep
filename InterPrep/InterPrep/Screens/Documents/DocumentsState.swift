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
    public var showingCreateNoteSheet: Bool = false
    public var showingEditNoteSheet: Bool = false
    public var editingNote: Document?
    /// URL загруженного файла для просмотра (QuickLook)
    public var documentURLToOpen: URL?
    
    public init() {}
}

// MARK: - Models

public struct Folder: Identifiable, Equatable, Sendable {
    public let id: UUID
    public var nodeId: UInt32?
    public var name: String
    public var documentsCount: Int
    public var createdAt: Date
    public var color: FolderColor
    
    public init(
        id: UUID = UUID(),
        nodeId: UInt32? = nil,
        name: String,
        documentsCount: Int = 0,
        createdAt: Date = Date(),
        color: FolderColor = .blue
    ) {
        self.id = id
        self.nodeId = nodeId
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
    public var content: String?
    
    public init(
        id: UUID = UUID(),
        name: String,
        type: DocumentType,
        size: Int64 = 0,
        createdAt: Date = Date(),
        modifiedAt: Date = Date(),
        folderId: UUID? = nil,
        url: URL? = nil,
        content: String? = nil
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.size = size
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
        self.folderId = folderId
        self.url = url
        self.content = content
    }
    
    public var formattedSize: String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: size)
    }
    
    public var isNote: Bool {
        type == .note || type == .txt
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
        case fileUploaded(URL, folderId: UUID?)
        case noteCreated(String, String)
        case noteUpdated(Document, String)
        case documentDeleted(Document)
        case clearDocumentToOpen
        case editNoteTapped(Document)
    }
    
    public enum Feedback: Sendable {
        case foldersLoaded([Folder])
        case recentDocumentsLoaded([Document])
        case foldersAndDocumentsLoaded([Folder], [Document])
        case loadingFailed(String)
        case documentDownloaded(URL)
        case documentOpenFailed(String)
        case noteContentLoaded(Document, String)
    }
    
    public enum Effect: Sendable {
        case loadFolders
        case loadRecentDocuments
        case createFolder(String)
        case uploadFile(URL, folderId: UUID?)
        case createNote(String, String)
        case updateNote(Document, String)
        case deleteDocument(UUID)
        case openDocument(Document)
        case loadNoteContent(Document)
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
            state.showingCreateNoteSheet = true
            return nil
            
        case .input(.dismissSheet):
            state.showingCreateFolderSheet = false
            state.showingUploadSheet = false
            state.showingCreateNoteSheet = false
            state.showingEditNoteSheet = false
            state.editingNote = nil
            return nil
            
        case .input(.folderCreated(let name)):
            state.showingCreateFolderSheet = false
            return .createFolder(name)
            
        case .input(.fileUploaded(let url, let folderId)):
            state.showingUploadSheet = false
            return .uploadFile(url, folderId: folderId)
            
        case .input(.noteCreated(let title, let content)):
            state.showingCreateNoteSheet = false
            return .createNote(title, content)
            
        case .input(.noteUpdated(let document, let content)):
            state.showingEditNoteSheet = false
            state.editingNote = nil
            return .updateNote(document, content)
            
        case .input(.editNoteTapped(let document)):
            state.editingNote = document
            return .loadNoteContent(document)
            
        case .input(.documentDeleted(let document)):
            state.recentDocuments.removeAll { $0.id == document.id }
            return .deleteDocument(document.id)
            
        case .input(.clearDocumentToOpen):
            state.documentURLToOpen = nil
            return nil
            
        case .feedback(.foldersLoaded(let folders)):
            state.folders = folders
            state.isLoading = false
            return nil
            
        case .feedback(.recentDocumentsLoaded(let documents)):
            state.recentDocuments = documents
            return nil
            
        case .feedback(.foldersAndDocumentsLoaded(let folders, let documents)):
            state.folders = folders
            state.recentDocuments = documents
            state.isLoading = false
            return nil
            
        case .feedback(.loadingFailed(let error)):
            state.isLoading = false
            state.error = error
            return nil
            
        case .feedback(.documentDownloaded(let url)):
            state.documentURLToOpen = url
            return nil
            
        case .feedback(.documentOpenFailed(let message)):
            state.error = message
            return nil
            
        case .feedback(.noteContentLoaded(let document, let content)):
            var updatedDoc = document
            updatedDoc.content = content
            state.editingNote = updatedDoc
            state.showingEditNoteSheet = true
            return nil
        }
    }
}
