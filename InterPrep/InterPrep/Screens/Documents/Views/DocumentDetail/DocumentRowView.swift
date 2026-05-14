import DesignSystem
import SwiftUI

struct DocumentRowView: View {
    let document: Document
    var showDate = false

    private var relativeDate: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.unitsStyle = .short
        return formatter.localizedString(for: document.createdAt, relativeTo: Date())
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: document.type.icon)
                .font(.title3)
                .foregroundColor(.brandPrimary)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(document.name)
                    .font(.body)
                    .lineLimit(1)
                    .foregroundColor(.primary)

                if showDate {
                    Text(relativeDate)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .contentShape(Rectangle())
    }
}

#Preview {
    VStack(spacing: 0) {
        DocumentRowView(document: Document(name: "Резюме iOS Developer.pdf", type: .pdf, size: 245_760))
        Divider().padding(.leading, 56)
        DocumentRowView(document: Document(name: "Заметки по интервью.txt", type: .note, size: 12_288))
        Divider().padding(.leading, 56)
        DocumentRowView(document: Document(name: "Портфолио проектов.pdf", type: .pdf, size: 1_048_576))
    }
}
