import DesignSystem
import SwiftUI

struct FolderCardView: View {
    let folder: Folder

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: "folder.fill")
                .font(.system(size: 40))
                .foregroundColor(.brandPrimary)

            Text(folder.name)
                .font(.caption)
                .fontWeight(.medium)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .foregroundColor(.primary)

            Text("\(folder.documentsCount)")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(minWidth: 1, maxWidth: .infinity)
        .padding(.vertical, 12)
    }
}

#Preview {
    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 4) {
        FolderCardView(folder: Folder(name: "Базы данных", documentsCount: 12, color: .blue))
        FolderCardView(folder: Folder(name: "Резюме", documentsCount: 5, color: .green))
        FolderCardView(folder: Folder(name: "Проекты", documentsCount: 8, color: .orange))
        FolderCardView(folder: Folder(name: "Дизайн", documentsCount: 3, color: .purple))
    }
    .padding()
}
