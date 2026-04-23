//
//  ResumeUploadView+Model.swift
//  InterPrep
//
//  Resume upload view model
//

import Foundation

extension ResumeUploadView {
    public struct Model {
        public let uploadStatus: ResumeUploadState.UploadStatus
        public let selectedFile: ResumeUploadState.SelectedFile?
        public let uploadProgress: Double
        public let errorMessage: String?
        public let onFileSelected: (URL) -> Void
        public let onUpload: () -> Void
        public let onCancel: () -> Void
        public let onSkip: () -> Void
        public let onRemoveFile: () -> Void
        
        public init(
            uploadStatus: ResumeUploadState.UploadStatus,
            selectedFile: ResumeUploadState.SelectedFile?,
            uploadProgress: Double,
            errorMessage: String?,
            onFileSelected: @escaping (URL) -> Void,
            onUpload: @escaping () -> Void,
            onCancel: @escaping () -> Void,
            onSkip: @escaping () -> Void,
            onRemoveFile: @escaping () -> Void
        ) {
            self.uploadStatus = uploadStatus
            self.selectedFile = selectedFile
            self.uploadProgress = uploadProgress
            self.errorMessage = errorMessage
            self.onFileSelected = onFileSelected
            self.onUpload = onUpload
            self.onCancel = onCancel
            self.onSkip = onSkip
            self.onRemoveFile = onRemoveFile
        }
    }
}

#if DEBUG
extension ResumeUploadView.Model {
    static func fixture(
        uploadStatus: ResumeUploadState.UploadStatus = .idle,
        selectedFile: ResumeUploadState.SelectedFile? = nil,
        uploadProgress: Double = 0.0,
        errorMessage: String? = nil,
        onFileSelected: @escaping (URL) -> Void = { _ in },
        onUpload: @escaping () -> Void = {},
        onCancel: @escaping () -> Void = {},
        onSkip: @escaping () -> Void = {},
        onRemoveFile: @escaping () -> Void = {}
    ) -> Self {
        .init(
            uploadStatus: uploadStatus,
            selectedFile: selectedFile,
            uploadProgress: uploadProgress,
            errorMessage: errorMessage,
            onFileSelected: onFileSelected,
            onUpload: onUpload,
            onCancel: onCancel,
            onSkip: onSkip,
            onRemoveFile: onRemoveFile
        )
    }
    
    static var idle: Self {
        .fixture()
    }
    
    static var withFile: Self {
        .fixture(
            uploadStatus: .selected,
            selectedFile: .init(
                name: "resume.pdf",
                size: 1_500_000,
                url: URL(fileURLWithPath: "/tmp/resume.pdf"),
                type: .pdf
            )
        )
    }
    
    static var uploading: Self {
        .fixture(
            uploadStatus: .uploading,
            selectedFile: .init(
                name: "resume.pdf",
                size: 1_500_000,
                url: URL(fileURLWithPath: "/tmp/resume.pdf"),
                type: .pdf
            ),
            uploadProgress: 0.5
        )
    }
    
    static var success: Self {
        .fixture(
            uploadStatus: .success,
            selectedFile: .init(
                name: "resume.pdf",
                size: 1_500_000,
                url: URL(fileURLWithPath: "/tmp/resume.pdf"),
                type: .pdf
            ),
            uploadProgress: 1.0
        )
    }
    
    static var error: Self {
        .fixture(
            uploadStatus: .failed,
            errorMessage: "Файл слишком большой. Максимальный размер: 10 МБ"
        )
    }
}
#endif
