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
            VStack(alignment: .leading, spacing: 12) {
                Circle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 40, height: 40)
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
                
                HStack(spacing: 4) {
                    Image(systemName: vacancy.isRemote ? "network" : "mappin.circle.fill")
                        .font(.caption)
                    Text(vacancy.location)
                        .font(.caption)
                }
                .foregroundColor(.secondary)
            }
            .padding(16)
            .frame(width: 200, height: 220)
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.gray.opacity(0.1), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview

#if DEBUG
struct VacancyCardCompact_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
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
