//
//  ResumeUploadContainer.swift
//  InterPrep
//
//  Resume upload container
//

import ArchitectureCore
import DesignSystem
import SwiftUI

public struct ResumeUploadContainer: View {
    @State private var store: ResumeUploadStore
    @State private var isClosing = false
    let onComplete: () -> Void
    let onCancel: () -> Void
    
    public init(
        store: ResumeUploadStore,
        onComplete: @escaping () -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.store = store
        self.onComplete = onComplete
        self.onCancel = onCancel
    }
    
    public var body: some View {
        ZStack {
            ResumeUploadView(model: makeModel())
                .opacity(isClosing ? 0 : 1)
            
            if isClosing {
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(.white)
                    Text("Загружаем вакансии...")
                        .font(.headline)
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(LinearGradient.brandBackground)
            }
        }
        .onChange(of: store.state.uploadStatus) { _, newStatus in
            if newStatus == .success {
                isClosing = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    onComplete()
                }
            }
        }
    }
    
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

#Preview {
    ResumeUploadContainer(
        store: Store(
            state: ResumeUploadState(),
            effectHandler: ResumeUploadEffectHandler(
                fileService: FileUploadServiceImpl()
            )
        ),
        onComplete: {},
        onCancel: {}
    )
}
