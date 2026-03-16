//
//  ResumeUploadView.swift
//  InterPrep
//
//  Resume upload view - passive
//

import SwiftUI
import UniformTypeIdentifiers
import DesignSystem

struct ResumeUploadView: View {
    let model: Model
    @State private var showDocumentPicker = false
    
    var body: some View {
        VStack(spacing: 0) {
            header
            
            ScrollView {
                VStack(spacing: Layout.sectionSpacing) {
                    illustration
                    titleSection
                    
                    if let file = model.selectedFile {
                        fileCard(file: file)
                    } else {
                        selectFileButton
                    }
                    
                    supportedFormatsSection
                    
                    if let error = model.errorMessage {
                        errorSection(error)
                    }
                }
                .padding(.horizontal, Layout.horizontalPadding)
                .padding(.top, Layout.topPadding)
            }
            
            bottomButtons
        }
        .background(LinearGradient.brandBackground)
        .sheet(isPresented: $showDocumentPicker) {
            DocumentPicker(onFilePicked: model.onFileSelected)
        }
    }
    
    // MARK: - Subviews
    
    @ViewBuilder
    private var header: some View {
        HStack {
            Button {
                model.onCancel()
            } label: {
                Image(systemName: "xmark")
                    .font(.title3)
                    .foregroundColor(.textPrimary)
                    .padding()
            }
            
            Spacer()
            
            Button("Пропустить") {
                model.onSkip()
            }
            .foregroundColor(.textTertiary)
            .padding()
        }
    }
    
    @ViewBuilder
    private var illustration: some View {
        ZStack {
            Image("upload_resume")
                .resizable()
                .scaledToFit()
                .frame(width: 200, height: 200)
            
            if model.uploadStatus == .uploading {
                VStack {
                    Spacer()
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(1.5)
                }
                .frame(height: 200)
            } else if model.uploadStatus == .success {
                VStack {
                    Spacer()
                    Image(systemName: "checkmark.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 60, height: 60)
                        .foregroundColor(.green)
                }
                .frame(height: 200)
            }
        }
        .padding(.top, Layout.illustrationTopPadding)
    }
    
    @ViewBuilder
    private var titleSection: some View {
        VStack(spacing: 12) {
            Text(titleText)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.textPrimary)
                .multilineTextAlignment(.center)
            
            Text(subtitleText)
                .font(.body)
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
        }
    }
    
    private var titleText: String {
        switch model.uploadStatus {
        case .idle, .selected, .failed:
            return "Загрузите резюме"
        case .uploading:
            return "Загружаем..."
        case .success:
            return "Готово!"
        }
    }
    
    private var subtitleText: String {
        switch model.uploadStatus {
        case .idle, .selected, .failed:
            return "Мы подберем вакансии\nспециально для вас"
        case .uploading:
            return "Пожалуйста, подождите"
        case .success:
            return "Резюме успешно загружено"
        }
    }
    
    @ViewBuilder
    private func fileCard(file: ResumeUploadState.SelectedFile) -> some View {
        HStack(spacing: 16) {
            Image(systemName: file.type.icon)
                .font(.largeTitle)
                .foregroundColor(.brandPrimary)
                .frame(width: 50, height: 50)
                .background(Color.white.opacity(0.2))
                .cornerRadius(10)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(file.name)
                    .font(.headline)
                    .foregroundColor(.textPrimary)
                    .lineLimit(1)
                
                HStack(spacing: 8) {
                    Text(file.type.rawValue)
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                    
                    Text("•")
                        .foregroundColor(.textSecondary)
                    
                    Text(file.formattedSize)
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                }
            }
            
            Spacer()
            
            if model.uploadStatus != .uploading && model.uploadStatus != .success {
                Button {
                    model.onRemoveFile()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(.textTertiary)
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.15))
        .cornerRadius(12)
        
        // Progress bar
        if model.uploadStatus == .uploading {
            VStack(spacing: 8) {
                ProgressView(value: model.uploadProgress)
                    .tint(.white)
                
                Text("\(Int(model.uploadProgress * 100))%")
                    .font(.caption)
                    .foregroundColor(.textSecondary)
            }
        }
    }
    
    @ViewBuilder
    private var selectFileButton: some View {
        Button {
            showDocumentPicker = true
        } label: {
            VStack(spacing: 16) {
                Image(systemName: "arrow.up.doc.fill")
                    .font(.largeTitle)
                    .foregroundColor(.white)
                
                Text("Выбрать файл")
                    .font(.headline)
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 150)
            .background(Color.white.opacity(0.15))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.3), style: StrokeStyle(lineWidth: 2, dash: [10]))
            )
        }
    }
    
    @ViewBuilder
    private var supportedFormatsSection: some View {
        VStack(spacing: 8) {
            Text("Поддерживаемые форматы:")
                .font(.caption)
                .foregroundColor(.textSecondary)
            
            HStack(spacing: 12) {
                ForEach(["PDF", "DOC", "DOCX", "TXT"], id: \.self) { format in
                    Text(format)
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(.textPrimary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(8)
                }
            }
            
            Text("Максимальный размер: 10 МБ")
                .font(.caption2)
                .foregroundColor(.textTertiary)
                .padding(.top, 4)
        }
    }
    
    @ViewBuilder
    private func errorSection(_ error: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.red)
            
            Text(error)
                .font(.subheadline)
                .foregroundColor(.red)
            
            Spacer()
        }
        .padding()
        .background(Color.red.opacity(0.2))
        .cornerRadius(12)
    }
    
    @ViewBuilder
    private var bottomButtons: some View {
        VStack(spacing: 12) {
            if model.selectedFile != nil && model.uploadStatus != .success {
                Button {
                    model.onUpload()
                } label: {
                    if model.uploadStatus == .uploading {
                        ProgressView()
                            .tint(.brandPrimary)
                    } else {
                        Text("Загрузить")
                            .font(.headline)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: Layout.buttonHeight)
                .background(Color.buttonBackground)
                .foregroundColor(.buttonText)
                .cornerRadius(12)
                .disabled(model.uploadStatus == .uploading)
            }
        }
        .padding(.horizontal, Layout.horizontalPadding)
        .padding(.bottom, Layout.bottomPadding)
    }
}

// MARK: - Model

extension ResumeUploadView {
    struct Model {
        let uploadStatus: ResumeUploadState.UploadStatus
        let selectedFile: ResumeUploadState.SelectedFile?
        let uploadProgress: Double
        let errorMessage: String?
        let onFileSelected: (URL) -> Void
        let onUpload: () -> Void
        let onCancel: () -> Void
        let onSkip: () -> Void
        let onRemoveFile: () -> Void
    }
}

// MARK: - Layout

private extension ResumeUploadView {
    enum Layout {
        static var horizontalPadding: CGFloat { 24 }
        static var topPadding: CGFloat { 24 }
        static var sectionSpacing: CGFloat { 24 }
        static var illustrationTopPadding: CGFloat { 20 }
        static var buttonHeight: CGFloat { 50 }
        static var bottomPadding: CGFloat { 32 }
    }
}

// MARK: - Document Picker

struct DocumentPicker: UIViewControllerRepresentable {
    let onFilePicked: (URL) -> Void
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(
            forOpeningContentTypes: [
                .pdf,
                .plainText,
                UTType(filenameExtension: "doc") ?? .data,
                UTType(filenameExtension: "docx") ?? .data
            ]
        )
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = false
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onFilePicked: onFilePicked)
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let onFilePicked: (URL) -> Void
        
        init(onFilePicked: @escaping (URL) -> Void) {
            self.onFilePicked = onFilePicked
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }
            guard url.startAccessingSecurityScopedResource() else { return }
            defer { url.stopAccessingSecurityScopedResource() }

            let tempDir = FileManager.default.temporaryDirectory
            let tempURL = tempDir.appendingPathComponent(url.lastPathComponent)
            do {
                if FileManager.default.fileExists(atPath: tempURL.path) {
                    try FileManager.default.removeItem(at: tempURL)
                }
                try FileManager.default.copyItem(at: url, to: tempURL)
                onFilePicked(tempURL)
            } catch {
                onFilePicked(url)
            }
        }
    }
}

// MARK: - Fixtures

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

// MARK: - Previews

#Preview("Idle") {
    ResumeUploadView(model: .idle)
}

#Preview("With File") {
    ResumeUploadView(model: .withFile)
}

#Preview("Uploading") {
    ResumeUploadView(model: .uploading)
}

#Preview("Success") {
    ResumeUploadView(model: .success)
}

#Preview("Error") {
    ResumeUploadView(model: .error)
}
