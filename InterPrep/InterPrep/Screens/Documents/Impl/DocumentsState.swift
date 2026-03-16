//
//  DocumentsState.swift
//  InterPrep
//
//  Documents state management
//

import Foundation
import ArchitectureCore

public struct DocumentsState {
    public var folders: [Folder] = []
    public var recentDocuments: [Document] = []
    public var selectedFolder: Folder?
    public var folderContentsFolders: [Folder] = []
    public var folderContentsDocuments: [Document] = []
    public var isLoading: Bool = false
    public var error: String?
    public var showingCreateFolderSheet: Bool = false
    public var folderToRename: Folder?
    public var folderToDelete: Folder?
    public var showingUploadSheet: Bool = false
    public var showingCreateNoteSheet: Bool = false
    public var showingEditNoteSheet: Bool = false
    public var editingNote: Document?
    public var documentURLToOpen: URL?
    
    public init() {}
}

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

    public var fileExtension: String {
        switch self {
        case .pdf: return "pdf"
        case .doc: return "doc"
        case .docx: return "docx"
        case .txt, .note: return "txt"
        case .image: return "jpg"
        case .other: return ""
        }
    }
}

extension DocumentsState: FeatureState {
    public enum Input: Sendable {
        case onAppear
        case folderTapped(Folder)
        case backFromFolder
        case documentTapped(Document)
        case createFolderTapped
        case uploadFileTapped
        case createNoteTapped
        case dismissSheet
        case folderCreated(String)
        case fileUploaded(URL, folderId: UUID?)
        case noteCreated(String, String)
        case noteUpdated(Document, String, String)
        case documentDeleted(Document)
        case clearDocumentToOpen
        case editNoteTapped(Document)
        case clearError
        case renameFolderTapped(Folder)
        case commitFolderRename(String)
        case cancelFolderRename
        case deleteFolderTapped(Folder)
        case confirmDeleteFolder(Folder)
        case dismissDeleteFolderConfirmation
    }
    
    public enum Feedback: Sendable {
        case foldersLoaded([Folder])
        case recentDocumentsLoaded([Document])
        case foldersAndDocumentsLoaded([Folder], [Document])
        case folderContentsLoaded([Folder], [Document])
        case folderDeletedAndRefreshed(deletedFolderId: UUID, [Folder], [Document])
        case folderRenamedAndRefreshed(folderId: UUID, newName: String, [Folder], [Document])
        case noteUpdatedAndRefreshed([Folder], [Document])
        case loadingFailed(String)
        case documentDownloaded(URL)
        case documentOpenFailed(String)
        case noteContentLoaded(Document, String)
    }
    
    public enum Effect: Sendable {
        case loadFolders
        case loadRecentDocuments
        case createFolder(String, parentFolder: Folder?)
        case loadFolderContents(Folder)
        case uploadFile(URL, folderId: UUID?)
        case createNote(String, String, parentFolder: Folder?)
        case updateNote(Document, String, String)
        case deleteDocument(UUID)
        case renameFolder(Folder, String)
        case deleteFolder(Folder)
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
            return .loadFolders
            
        case .input(.folderTapped(let folder)):
            state.selectedFolder = folder
            state.isLoading = true
            return .loadFolderContents(folder)

        case .input(.backFromFolder):
            state.selectedFolder = nil
            state.folderContentsFolders = []
            state.folderContentsDocuments = []
            return nil
            
        case .input(.documentTapped(let document)):
            return .openDocument(document)
            
        case .input(.createFolderTapped):
            state.showingCreateFolderSheet = true
            state.error = nil
            return nil
            
        case .input(.uploadFileTapped):
            state.showingUploadSheet = true
            state.error = nil
            return nil
            
        case .input(.createNoteTapped):
            state.showingCreateNoteSheet = true
            state.error = nil
            return nil
            
        case .input(.dismissSheet):
            state.showingCreateFolderSheet = false
            state.folderToRename = nil
            state.showingUploadSheet = false
            state.showingCreateNoteSheet = false
            state.showingEditNoteSheet = false
            state.editingNote = nil
            return nil

        case .input(.renameFolderTapped(let folder)):
            state.folderToRename = folder
            return nil

        case .input(.commitFolderRename(let newName)):
            guard let folder = state.folderToRename else { return nil }
            state.folderToRename = nil
            return .renameFolder(folder, newName.trimmingCharacters(in: .whitespacesAndNewlines))

        case .input(.deleteFolderTapped(let folder)):
            state.folderToDelete = folder
            return nil

        case .input(.confirmDeleteFolder(let folder)):
            state.folderToDelete = nil
            return .deleteFolder(folder)

        case .input(.cancelFolderRename):
            state.folderToRename = nil
            return nil

        case .input(.dismissDeleteFolderConfirmation):
            state.folderToDelete = nil
            return nil
            
        case .input(.folderCreated(let name)):
            state.showingCreateFolderSheet = false
            return .createFolder(name, parentFolder: state.selectedFolder)
            
        case .input(.fileUploaded(let url, let folderId)):
            state.showingUploadSheet = false
            return .uploadFile(url, folderId: folderId)
            
        case .input(.noteCreated(let title, let content)):
            state.showingCreateNoteSheet = false
            return .createNote(title, content, parentFolder: state.selectedFolder)
            
        case .input(.noteUpdated(let document, let newName, let content)):
            return .updateNote(document, newName, content)
            
        case .input(.editNoteTapped(let document)):
            state.editingNote = document
            return .loadNoteContent(document)
            
        case .input(.documentDeleted(let document)):
            return .deleteDocument(document.id)
            
        case .input(.clearDocumentToOpen):
            state.documentURLToOpen = nil
            return nil
            
        case .input(.clearError):
            state.error = nil
            return nil
            
        case .feedback(.foldersLoaded(let folders)):
            state.folders = folders
            state.isLoading = false
            state.error = nil
            return nil
            
        case .feedback(.recentDocumentsLoaded(let documents)):
            state.recentDocuments = documents
            state.error = nil
            return nil
            
        case .feedback(.foldersAndDocumentsLoaded(let folders, let documents)):
            state.folders = folders
            state.recentDocuments = documents
            state.isLoading = false
            state.error = nil
            if state.selectedFolder != nil {
                return .loadFolderContents(state.selectedFolder!)
            }
            return nil

        case .feedback(.folderContentsLoaded(let folders, let documents)):
            state.folderContentsFolders = folders
            state.folderContentsDocuments = documents
            state.isLoading = false
            state.error = nil
            return nil

        case .feedback(.noteUpdatedAndRefreshed(let folders, let documents)):
            state.folders = folders
            state.recentDocuments = documents
            state.showingEditNoteSheet = false
            state.editingNote = nil
            state.isLoading = false
            state.error = nil
            if state.selectedFolder != nil {
                return .loadFolderContents(state.selectedFolder!)
            }
            return nil

        case .feedback(.folderDeletedAndRefreshed(let deletedFolderId, let folders, let documents)):
            state.folders = folders
            state.recentDocuments = documents
            state.isLoading = false
            state.error = nil
            if state.selectedFolder?.id == deletedFolderId {
                state.selectedFolder = nil
                state.folderContentsFolders = []
                state.folderContentsDocuments = []
            }
            if state.folderToRename?.id == deletedFolderId {
                state.folderToRename = nil
            }
            return nil

        case .feedback(.folderRenamedAndRefreshed(let folderId, let newName, let folders, let documents)):
            state.folders = folders
            state.recentDocuments = documents
            state.isLoading = false
            state.error = nil
            if state.selectedFolder?.id == folderId {
                var updated = state.selectedFolder!
                updated.name = newName
                state.selectedFolder = updated
            }
            if state.folderToRename?.id == folderId {
                state.folderToRename = nil
            }
            if state.selectedFolder != nil {
                return .loadFolderContents(state.selectedFolder!)
            }
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
