//
//  DocumentRowView.swift
//  InterPrep
//
//  Document row component
//

import DesignSystem
import SwiftUI

struct DocumentRowView: View {
    let document: Document
    @Environment(\.colorScheme) var colorScheme
    
    private let relativeDate: String
    
    init(document: Document) {
        self.document = document
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.unitsStyle = .short
        self.relativeDate = formatter.localizedString(for: document.createdAt, relativeTo: Date())
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: document.type.icon)
                .font(.title2)
                .foregroundColor(.brandPrimary)
                .frame(width: 40, height: 40)
                .background(Color.brandPrimary.opacity(0.1))
                .cornerRadius(8)

            VStack(alignment: .leading, spacing: 4) {
                Text(document.name)
                    .font(.body)
                    .fontWeight(.medium)
                    .lineLimit(1)
                    .foregroundColor(.textOnBackground)

                HStack(spacing: 8) {
                    Text(document.formattedSize)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("•")
                        .foregroundColor(.secondary)
                    
                    Text(relativeDate)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(minWidth: 1)
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(12)
        .shadow(color: shadowColor, radius: 4, x: 0, y: 2)
    }
    
    private var shadowColor: Color {
        colorScheme == .dark ? .clear : .black.opacity(0.05)
    }
}

#Preview {
    VStack(spacing: 12) {
        DocumentRowView(
            document: Document(
                name: "Резюме iOS Developer.pdf",
                type: .pdf,
                size: 245_760,
                createdAt: Date().addingTimeInterval(-86400)
            )
        )
        
        DocumentRowView(
            document: Document(
                name: "Заметки по интервью.txt",
                type: .note,
                size: 12_288,
                createdAt: Date().addingTimeInterval(-172800)
            )
        )
        
        DocumentRowView(
            document: Document(
                name: "Портфолио проектов.pdf",
                type: .pdf,
                size: 1_048_576,
                createdAt: Date().addingTimeInterval(-259200)
            )
        )
    }
    .padding()
}
