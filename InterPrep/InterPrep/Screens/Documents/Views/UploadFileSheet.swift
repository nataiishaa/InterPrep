import DesignSystem
import SwiftUI
import UniformTypeIdentifiers

struct UploadFileSheet: View {
    @State private var showingDocumentPicker = false
    @State private var pulseScale: CGFloat = 1.0
    let onDismiss: () -> Void
    let onFileSelected: ((URL) -> Void)?

    init(onDismiss: @escaping () -> Void, onFileSelected: ((URL) -> Void)? = nil) {
        self.onDismiss = onDismiss
        self.onFileSelected = onFileSelected
    }

    var body: some View {
        ZStack {
            LinearGradient.brandBackground
                .ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                iconView

                VStack(spacing: 12) {
                    Text("Загрузить файл")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)

                    Text("Выберите документ из файлов")
                        .font(.body)
                        .foregroundColor(.white.opacity(0.8))
                }

                Spacer()

                VStack(spacing: 16) {
                    Button {
                        showingDocumentPicker = true
                    } label: {
                        HStack {
                            Image(systemName: "folder.fill")
                            Text("Выбрать файл")
                        }
                        .font(.headline)
                        .foregroundColor(.brandPrimary)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(14)
                    }

                    Button {
                        onDismiss()
                    } label: {
                        Text("Отмена")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                pulseScale = 1.1
            }
        }
        .fileImporter(
            isPresented: $showingDocumentPicker,
            allowedContentTypes: [.pdf, .plainText, .image, .data],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    onFileSelected?(url)
                    onDismiss()
                }
            case .failure:
                break
            }
        }
    }

    @ViewBuilder
    private var iconView: some View {
        ZStack {
            Circle()
                .fill(.white.opacity(0.08))
                .frame(width: 140, height: 140)
                .scaleEffect(pulseScale)

            Circle()
                .fill(.white.opacity(0.12))
                .frame(width: 110, height: 110)

            Circle()
                .fill(.white.opacity(0.18))
                .frame(width: 80, height: 80)

            Image(systemName: "arrow.up.doc.fill")
                .font(.system(size: 36, weight: .medium))
                .foregroundColor(.white)
        }
    }
}

#Preview {
    UploadFileSheet(onDismiss: {})
}
