import DesignSystem
import SwiftUI
import UniformTypeIdentifiers

struct UploadFileSheet: View {
    private enum IconDecoration {
        static let outerRingSize: CGFloat = 140
        static let outerRingOpacity: Double = 0.08
        static let middleRingSize: CGFloat = 110
        static let middleRingOpacity: Double = 0.12
        static let innerRingSize: CGFloat = 80
        static let innerRingOpacity: Double = 0.18
        static let symbolName = "arrow.up.doc.fill"
        static let symbolPointSize: CGFloat = 36
    }

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
                .fill(.white.opacity(IconDecoration.outerRingOpacity))
                .frame(width: IconDecoration.outerRingSize, height: IconDecoration.outerRingSize)
                .scaleEffect(pulseScale)

            Circle()
                .fill(.white.opacity(IconDecoration.middleRingOpacity))
                .frame(width: IconDecoration.middleRingSize, height: IconDecoration.middleRingSize)

            Circle()
                .fill(.white.opacity(IconDecoration.innerRingOpacity))
                .frame(width: IconDecoration.innerRingSize, height: IconDecoration.innerRingSize)

            Image(systemName: IconDecoration.symbolName)
                .font(.system(size: IconDecoration.symbolPointSize, weight: .medium))
                .foregroundColor(.white)
        }
    }
}

#Preview {
    UploadFileSheet(onDismiss: {})
}
