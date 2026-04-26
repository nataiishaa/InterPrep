//
//  VacancyCardCompact.swift
//  VacancyCardModule
//
//  Компактная карточка для горизонтального скролла
//

import SwiftUI

public struct VacancyCardCompact: View {
    let vacancy: Vacancy
    let onTap: () -> Void
    
    public init(vacancy: Vacancy, onTap: @escaping () -> Void = {}) {
        self.vacancy = vacancy
        self.onTap = onTap
    }
    
    public var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: Layout.vStackSpacing) {
                Circle()
                    .fill(Color.gray.opacity(Layout.avatarPlaceholderOpacity))
                    .frame(width: Layout.avatarSize, height: Layout.avatarSize)
                    .overlay(
                        Text(vacancy.company.prefix(1))
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.gray)
                    )
                
                Text(vacancy.title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .lineLimit(2)
                    .foregroundColor(.primary)
                
                Text(vacancy.company)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                Spacer()
                
                if let salary = vacancy.salary {
                    Text(salary.formatted)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                }
                
                HStack(spacing: Layout.metaRowSpacing) {
                    Image(systemName: vacancy.isRemote ? "network" : "mappin.circle.fill")
                        .font(.caption)
                    Text(vacancy.location)
                        .font(.caption)
                }
                .foregroundColor(.secondary)
            }
            .padding(Layout.contentPadding)
            .frame(width: Layout.cardWidth, height: Layout.cardHeight)
            .background(Color(.systemBackground))
            .cornerRadius(Layout.cornerRadius)
            .shadow(
                color: Color.black.opacity(Layout.shadowOpacity),
                radius: Layout.shadowRadius,
                x: Layout.shadowOffsetX,
                y: Layout.shadowOffsetY
            )
            .overlay(
                RoundedRectangle(cornerRadius: Layout.cornerRadius)
                    .stroke(Color.gray.opacity(Layout.borderOpacity), lineWidth: Layout.borderLineWidth)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

extension VacancyCardCompact {
    enum Layout {
        static let vStackSpacing: CGFloat = 12
        static let avatarSize: CGFloat = 40
        static let avatarPlaceholderOpacity: Double = 0.2
        static let metaRowSpacing: CGFloat = 4
        static let contentPadding: CGFloat = 16
        static let cardWidth: CGFloat = 200
        static let cardHeight: CGFloat = 220
        static let cornerRadius: CGFloat = 16
        static let shadowOpacity: Double = 0.05
        static let shadowRadius: CGFloat = 8
        static let shadowOffsetX: CGFloat = 0
        static let shadowOffsetY: CGFloat = 2
        static let borderOpacity: Double = 0.1
        static let borderLineWidth: CGFloat = 1
        static let previewCardsSpacing: CGFloat = 16
    }
}

// MARK: - Preview

#if DEBUG
struct VacancyCardCompact_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: VacancyCardCompact.Layout.previewCardsSpacing) {
                VacancyCardCompact(vacancy: .mock1)
                VacancyCardCompact(vacancy: .mock2)
                VacancyCardCompact(vacancy: .mock3)
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
    }
}
#endif
