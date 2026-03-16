//
//  DocumentServicing.swift
//  InterPrep
//
//  Document service protocol (operations over folders and documents)
//

import Foundation

public protocol DocumentServicing: Actor {
    func fetchFolders() async throws -> [Folder]
    func fetchRecentDocuments() async throws -> [Document]
    func fetchFolderContents(parentNodeId: UInt32) async throws -> (folders: [Folder], documents: [Document])
    func createFolder(name: String, parentId: UInt32?) async throws
    func uploadFile(url: URL, folderId: UUID?) async throws
    func createNote(title: String, content: String, parentId: UInt32?) async throws
    func updateNote(document: Document, newName: String, content: String) async throws
    func loadNoteContent(id: UUID) async throws -> String
    func deleteDocument(id: UUID) async throws
    func renameFolder(folder: Folder, newName: String) async throws
    func deleteFolder(folder: Folder) async throws
    func downloadDocument(id: UUID) async throws -> (Data, String)
}
