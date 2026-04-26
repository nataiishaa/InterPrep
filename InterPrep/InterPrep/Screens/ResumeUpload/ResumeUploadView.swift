//
//  ResumeUploadView.swift
//  InterPrep
//
//  Resume upload view - passive
//

import DesignSystem
import SwiftUI
import UniformTypeIdentifiers

public struct ResumeUploadView: View {
    let model: Model
    @State private var showDocumentPicker = false
    
    public init(model: Model) {
        self.model = model
    }
    
    public var body: some View {
        VStack(spacing: .zero) {
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
                    .padding(Layout.headerToolbarButtonPadding)
            }
            
            Spacer()
            
            Button("Пропустить") {
                model.onSkip()
            }
            .foregroundColor(.textTertiary)
            .padding(Layout.headerToolbarButtonPadding)
        }
    }
    
    @ViewBuilder
    private var illustration: some View {
        ZStack {
            Image("upload_resume")
                .resizable()
                .scaledToFit()
                .frame(width: Layout.illustrationSize, height: Layout.illustrationSize)
            
            if model.uploadStatus == .uploading {
                VStack {
                    Spacer()
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(Layout.uploadProgressScale)
                }
                .frame(height: Layout.illustrationSize)
            } else if model.uploadStatus == .success {
                VStack {
                    Spacer()
                    Image(systemName: "checkmark.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: Layout.successIconSize, height: Layout.successIconSize)
                        .foregroundColor(.green)
                }
                .frame(height: Layout.illustrationSize)
            }
        }
        .padding(.top, Layout.illustrationTopPadding)
    }
    
    @ViewBuilder
    private var titleSection: some View {
        VStack(spacing: Layout.titleSectionSpacing) {
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
        HStack(spacing: Layout.fileCardHStackSpacing) {
            Image(systemName: file.type.icon)
                .font(.largeTitle)
                .foregroundColor(.brandPrimary)
                .frame(width: Layout.fileCardIconSize, height: Layout.fileCardIconSize)
                .background(Color.white.opacity(Layout.fileCardIconBackgroundOpacity))
                .cornerRadius(Layout.fileCardIconCornerRadius)
            
            VStack(alignment: .leading, spacing: Layout.fileCardTextVStackSpacing) {
                Text(file.name)
                    .font(.headline)
                    .foregroundColor(.textPrimary)
                    .lineLimit(1)
                
                HStack(spacing: Layout.fileCardMetaHStackSpacing) {
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
        .padding(Layout.cardContentPadding)
        .background(Color.white.opacity(Layout.fileCardBackgroundOpacity))
        .cornerRadius(Layout.cardCornerRadius)
    }
    
    @ViewBuilder
    private var selectFileButton: some View {
        Button {
            showDocumentPicker = true
        } label: {
            VStack(spacing: Layout.selectFileDropZoneVStackSpacing) {
                Image(systemName: "arrow.up.doc.fill")
                    .font(.largeTitle)
                    .foregroundColor(.white)
                
                Text("Выбрать файл")
                    .font(.headline)
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .frame(height: Layout.selectFileDropZoneHeight)
            .background(Color.white.opacity(Layout.selectFileDropZoneBackgroundOpacity))
            .cornerRadius(Layout.cardCornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: Layout.cardCornerRadius)
                    .stroke(
                        Color.white.opacity(Layout.selectFileDropZoneBorderOpacity),
                        style: StrokeStyle(lineWidth: Layout.selectFileBorderLineWidth, dash: Layout.selectFileBorderDash)
                    )
            )
        }
    }
    
    @ViewBuilder
    private var supportedFormatsSection: some View {
        VStack(spacing: Layout.supportedFormatsSectionSpacing) {
            Text("Поддерживаемые форматы:")
                .font(.caption)
                .foregroundColor(.textSecondary)
            
            HStack(spacing: Layout.supportedFormatsRowSpacing) {
                ForEach(["PDF", "DOC", "DOCX", "TXT"], id: \.self) { format in
                    Text(format)
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(.textPrimary)
                        .padding(.horizontal, Layout.formatChipHorizontalPadding)
                        .padding(.vertical, Layout.formatChipVerticalPadding)
                        .background(Color.white.opacity(Layout.formatChipBackgroundOpacity))
                        .cornerRadius(Layout.formatChipCornerRadius)
                }
            }
            
            Text("Максимальный размер: 10 МБ")
                .font(.caption2)
                .foregroundColor(.textTertiary)
                .padding(.top, Layout.supportedFormatsHintTopPadding)
        }
    }
    
    @ViewBuilder
    private func errorSection(_ error: String) -> some View {
        HStack(spacing: Layout.errorBannerHStackSpacing) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.red)
            
            Text(error)
                .font(.subheadline)
                .foregroundColor(.red)
            
            Spacer()
        }
        .padding(Layout.cardContentPadding)
        .background(Color.red.opacity(Layout.errorBannerBackgroundOpacity))
        .cornerRadius(Layout.cardCornerRadius)
    }
    
    @ViewBuilder
    private var bottomButtons: some View {
        VStack(spacing: Layout.bottomButtonsVStackSpacing) {
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
                .cornerRadius(Layout.cardCornerRadius)
                .disabled(model.uploadStatus == .uploading)
            }
        }
        .padding(.horizontal, Layout.horizontalPadding)
        .padding(.bottom, Layout.bottomPadding)
    }
}

// MARK: - Layout

private extension ResumeUploadView {
    enum Layout {
        static var horizontalPadding: CGFloat { 24 }
        static var headerToolbarButtonPadding: CGFloat { 16 }
        static var topPadding: CGFloat { 24 }
        static var sectionSpacing: CGFloat { 24 }
        static var illustrationTopPadding: CGFloat { 20 }
        static var buttonHeight: CGFloat { 50 }
        static var bottomPadding: CGFloat { 32 }

        static var illustrationSize: CGFloat { 200 }
        static var uploadProgressScale: CGFloat { 1.5 }
        static var successIconSize: CGFloat { 60 }

        static var titleSectionSpacing: CGFloat { 12 }

        static var fileCardHStackSpacing: CGFloat { 16 }
        static var fileCardIconSize: CGFloat { 50 }
        static var fileCardIconBackgroundOpacity: Double { 0.2 }
        static var fileCardIconCornerRadius: CGFloat { 10 }
        static var fileCardTextVStackSpacing: CGFloat { 4 }
        static var fileCardMetaHStackSpacing: CGFloat { 8 }
        static var fileCardBackgroundOpacity: Double { 0.15 }
        static var cardCornerRadius: CGFloat { 12 }
        static var cardContentPadding: CGFloat { 16 }

        static var selectFileDropZoneVStackSpacing: CGFloat { 16 }
        static var selectFileDropZoneHeight: CGFloat { 150 }
        static var selectFileDropZoneBackgroundOpacity: Double { 0.15 }
        static var selectFileDropZoneBorderOpacity: Double { 0.3 }
        static var selectFileBorderLineWidth: CGFloat { 2 }
        static var selectFileBorderDash: [CGFloat] { [10] }

        static var supportedFormatsSectionSpacing: CGFloat { 8 }
        static var supportedFormatsRowSpacing: CGFloat { 12 }
        static var formatChipHorizontalPadding: CGFloat { 12 }
        static var formatChipVerticalPadding: CGFloat { 6 }
        static var formatChipBackgroundOpacity: Double { 0.2 }
        static var formatChipCornerRadius: CGFloat { 8 }
        static var supportedFormatsHintTopPadding: CGFloat { 4 }

        static var errorBannerHStackSpacing: CGFloat { 12 }
        static var errorBannerBackgroundOpacity: Double { 0.2 }

        static var bottomButtonsVStackSpacing: CGFloat { 12 }
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
            guard let url = urls.first else {
                return
            }
            
            guard url.startAccessingSecurityScopedResource() else {
                return
            }
            defer { url.stopAccessingSecurityScopedResource() }

            let tempDir = FileManager.default.temporaryDirectory
            let fileExtension = url.pathExtension
            
            let timestamp = Int(Date().timeIntervalSince1970)
            let safeFileName = "resume_\(timestamp).\(fileExtension)"
            let tempURL = tempDir.appendingPathComponent(safeFileName)
            
            do {
                guard FileManager.default.fileExists(atPath: url.path) else {
                    let data = try Data(contentsOf: url)
                    try data.write(to: tempURL)
                    onFilePicked(tempURL)
                    return
                }
                
                if FileManager.default.fileExists(atPath: tempURL.path) {
                    try FileManager.default.removeItem(at: tempURL)
                }
                
                try FileManager.default.copyItem(at: url, to: tempURL)
                onFilePicked(tempURL)
            } catch {
                do {
                    let data = try Data(contentsOf: url)
                    try data.write(to: tempURL)
                    onFilePicked(tempURL)
                } catch {
                }
            }
        }
    }
}

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
