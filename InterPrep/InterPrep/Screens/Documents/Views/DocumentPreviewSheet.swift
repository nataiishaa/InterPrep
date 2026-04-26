import SwiftUI

struct DocumentPreviewSheet: View {
    let url: URL
    let onDismiss: () -> Void
    
    var body: some View {
        NavigationStack {
            QuickLookPreview(url: url)
                .navigationTitle(url.lastPathComponent)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Готово") {
                            onDismiss()
                        }
                    }
                }
        }
    }
}
