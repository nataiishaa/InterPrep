//
//  ResumeUploadState.swift
//  InterPrep
//
//  Resume upload state
//

import Foundation
import UniformTypeIdentifiers
import ArchitectureCore

public struct ResumeUploadState: FeatureState {
    public var uploadStatus: UploadStatus = .idle
    public var selectedFile: SelectedFile?
    public var uploadProgress: Double = 0.0
    public var errorMessage: String?
    
    public init() {}
    
    public enum UploadStatus: Sendable {
        case idle
        case selected
        case uploading
        case success
        case failed
    }
    
    public struct SelectedFile: Equatable, Sendable {
        public let name: String
        public let size: Int64
        public let url: URL
        public let type: FileType
        
        public init(name: String, size: Int64, url: URL, type: FileType) {
            self.name = name
            self.size = size
            self.url = url
            self.type = type
        }
        
        public enum FileType: String, Sendable {
            case pdf = "PDF"
            case doc = "DOC"
            case docx = "DOCX"
            case txt = "TXT"
            
            var icon: String {
                switch self {
                case .pdf: return "doc.fill"
                case .doc, .docx: return "doc.text.fill"
                case .txt: return "doc.plaintext.fill"
                }
            }
        }
        
        var formattedSize: String {
            let formatter = ByteCountFormatter()
            formatter.allowedUnits = [.useKB, .useMB]
            formatter.countStyle = .file
            return formatter.string(fromByteCount: size)
        }
    }
    
    public enum Input: Sendable {
        case selectFileTapped
        case fileSelected(URL)
        case uploadTapped
        case cancelTapped
        case skipTapped
        case removeFileTapped
    }
    
    public enum Feedback: Sendable {
        case fileValidated(SelectedFile)
        case fileValidationFailed(String)
        case uploadProgress(Double)
        case uploadCompleted
        case uploadFailed(String)
    }
    
    public enum Effect: Sendable {
        case validateFile(URL)
        case uploadFile(SelectedFile)
        case cancelUpload
        case navigateBack
        case navigateToMain
    }
    
    @MainActor
    public static func reduce(
        state: inout Self,
        with message: Message<Input, Feedback>
    ) -> Effect? {
        switch message {
        case .input(.selectFileTapped):
            return nil
            
        case let .input(.fileSelected(url)):
            state.uploadStatus = .idle
            state.errorMessage = nil
            return .validateFile(url)
            
        case .input(.uploadTapped):
            guard let file = state.selectedFile else { return nil }
            state.uploadStatus = .uploading
            state.uploadProgress = 0.0
            state.errorMessage = nil
            return .uploadFile(file)
            
        case .input(.cancelTapped):
            if state.uploadStatus == .uploading {
                return .cancelUpload
            }
            return .navigateBack
            
        case .input(.skipTapped):
            return .navigateToMain
            
        case .input(.removeFileTapped):
            state.selectedFile = nil
            state.uploadStatus = .idle
            state.uploadProgress = 0.0
            state.errorMessage = nil
            
        case let .feedback(.fileValidated(file)):
            state.selectedFile = file
            state.uploadStatus = .selected
            
        case let .feedback(.fileValidationFailed(error)):
            state.errorMessage = error
            state.uploadStatus = .failed
            
        case let .feedback(.uploadProgress(progress)):
            state.uploadProgress = progress
            
        case .feedback(.uploadCompleted):
            state.uploadStatus = .success
            state.uploadProgress = 1.0
            
        case let .feedback(.uploadFailed(error)):
            state.uploadStatus = .failed
            state.errorMessage = error
            state.uploadProgress = 0.0
        }
        
        return nil
    }
}
