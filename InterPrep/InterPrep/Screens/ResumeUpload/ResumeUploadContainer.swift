//
//  ResumeUploadContainer.swift
//  InterPrep
//
//  Resume upload container
//

import SwiftUI
import ArchitectureCore

public struct ResumeUploadContainer: View {
    public typealias ResumeUploadStore = Store<ResumeUploadState, ResumeUploadEffectHandler>
    
    @StateObject private var store: ResumeUploadStore
    let onComplete: () -> Void
    let onCancel: () -> Void
    
    public init(
        store: @autoclosure @escaping () -> ResumeUploadStore,
        onComplete: @escaping () -> Void,
        onCancel: @escaping () -> Void
    ) {
        _store = StateObject(wrappedValue: store())
        self.onComplete = onComplete
        self.onCancel = onCancel
    }
    
    public var body: some View {
        ResumeUploadView(model: makeModel())
            .onChange(of: store.state.uploadStatus) { _, newStatus in
                if newStatus == .success {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        onComplete()
                    }
                }
            }
    }
    
    // MARK: - Make Model
    
    private func makeModel() -> ResumeUploadView.Model {
        .init(
            uploadStatus: store.state.uploadStatus,
            selectedFile: store.state.selectedFile,
            uploadProgress: store.state.uploadProgress,
            errorMessage: store.state.errorMessage,
            onFileSelected: { url in
                store.send(.fileSelected(url))
            },
            onUpload: {
                store.send(.uploadTapped)
            },
            onCancel: {
                onCancel()
            },
            onSkip: {
                onComplete()
            },
            onRemoveFile: {
                store.send(.removeFileTapped)
            }
        )
    }
}

// MARK: - Preview

#Preview {
    ResumeUploadContainer(
        store: Store(
            state: ResumeUploadState(),
            effectHandler: ResumeUploadEffectHandler(
                fileService: FileUploadServiceMock()
            )
        ),
        onComplete: {},
        onCancel: {}
    )
}
