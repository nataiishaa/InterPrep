//
//  VacancyCardView.swift
//  VacancyCardModule
//
//  Компактная карточка вакансии для списка
//

import SwiftUI

public struct VacancyCardView: View {
    let vacancy: Vacancy
    let onTap: () -> Void
    
    public init(vacancy: Vacancy, onTap: @escaping () -> Void = {}) {
        self.vacancy = vacancy
        self.onTap = onTap
    }
    
    public var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                // Header: Company & Location
                HStack(alignment: .top, spacing: 12) {
                    // Company Logo Placeholder
                    Circle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 48, height: 48)
                        .overlay(
                            Text(vacancy.company.prefix(1))
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundColor(.gray)
                        )
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(vacancy.company)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 4) {
                            Image(systemName: vacancy.isRemote ? "network" : "mappin.circle.fill")
                                .font(.caption)
                            Text(vacancy.location)
                                .font(.caption)
                        }
                        .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    // Posted Date
                    Text(timeAgo(from: vacancy.postedDate))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                // Job Title
                Text(vacancy.title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .lineLimit(2)
                
                // Salary & Experience
                HStack(spacing: 16) {
                    if let salary = vacancy.salary {
                        Label(salary.formatted, systemImage: "rublesign.circle.fill")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.green)
                    }
                    
                    Label(vacancy.experienceLevel.displayName, systemImage: "star.fill")
                        .font(.subheadline)
                        .foregroundColor(.orange)
                }
                
                // Tags
                if !vacancy.tags.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(vacancy.tags.prefix(5), id: \.self) { tag in
                                Text(tag)
                                    .font(.caption)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(Color.blue.opacity(0.1))
                                    .foregroundColor(.blue)
                                    .cornerRadius(8)
                            }
                        }
                    }
                }
                
                // Employment Type
                HStack {
                    Image(systemName: employmentTypeIcon)
                        .font(.caption)
                    Text(vacancy.employmentType.displayName)
                        .font(.caption)
                    
                    Spacer()
                    
                    // Deadline if exists
                    if let deadline = vacancy.applicationDeadline {
                        HStack(spacing: 4) {
                            Image(systemName: "clock.fill")
                                .font(.caption2)
                            Text("до \(formatDate(deadline))")
                                .font(.caption2)
                        }
                        .foregroundColor(.red.opacity(0.8))
                    }
                }
                .foregroundColor(.secondary)
            }
            .padding(16)
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
    
    // MARK: - Helpers
    
    private var employmentTypeIcon: String {
        switch vacancy.employmentType {
        case .fullTime: return "briefcase.fill"
        case .partTime: return "briefcase"
        case .contract: return "doc.text.fill"
        case .internship: return "graduationcap.fill"
        case .freelance: return "laptopcomputer"
        }
    }
    
    private func timeAgo(from date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.day, .hour], from: date, to: now)
        
        if let days = components.day, days > 0 {
            return "\(days)д"
        } else if let hours = components.hour, hours > 0 {
            return "\(hours)ч"
        } else {
            return "Только что"
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM"
        formatter.locale = Locale(identifier: "ru_RU")
        return formatter.string(from: date)
    }
}

// MARK: - Preview

#if DEBUG
struct VacancyCardView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 16) {
            VacancyCardView(vacancy: .mock1)
            VacancyCardView(vacancy: .mock2)
            VacancyCardView(vacancy: .mock3)
        }
        .padding()
        .background(Color(.systemGroupedBackground))
    }
}
#endif
