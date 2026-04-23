//
//  FolderCardView.swift
//  InterPrep
//
//  Folder card component
//

import DesignSystem
import SwiftUI

struct FolderCardView: View {
    let folder: Folder
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "folder.fill")
                .font(.system(size: 50))
                .foregroundColor(folderColor)

            Text(folder.name)
                .font(.caption)
                .fontWeight(.medium)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .foregroundColor(.textOnBackground)

            Text("\(folder.documentsCount)")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(minWidth: 1, maxWidth: .infinity)
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(12)
        .shadow(color: shadowColor, radius: 4, x: 0, y: 2)
    }
    
    private var shadowColor: Color {
        colorScheme == .dark ? .clear : .black.opacity(0.05)
    }
    
    private var folderColor: Color {
        Color.brandPrimary
    }
}

// MARK: - Preview

#Preview {
    HStack(spacing: 16) {
        FolderCardView(
            folder: Folder(
                name: "Базы данных",
                documentsCount: 12,
                color: .blue
            )
        )
        
        FolderCardView(
            folder: Folder(
                name: "Резюме",
                documentsCount: 5,
                color: .green
            )
        )
        
        FolderCardView(
            folder: Folder(
                name: "Проекты",
                documentsCount: 8,
                color: .orange
            )
        )
    }
    .padding()
}
