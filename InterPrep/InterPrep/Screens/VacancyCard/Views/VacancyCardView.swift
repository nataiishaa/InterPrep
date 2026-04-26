//
//  VacancyCardView.swift
//  VacancyCardModule
//
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
            VStack(alignment: .leading, spacing: Layout.mainVStackSpacing) {
                HStack(alignment: .top, spacing: Layout.headerHStackSpacing) {
                    Circle()
                        .fill(Color.gray.opacity(Layout.avatarPlaceholderOpacity))
                        .frame(width: Layout.avatarSize, height: Layout.avatarSize)
                        .overlay(
                            Text(vacancy.company.prefix(1))
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundColor(.gray)
                        )
                    
                    VStack(alignment: .leading, spacing: Layout.companyBlockVStackSpacing) {
                        Text(vacancy.company)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: Layout.locationRowSpacing) {
                            Image(systemName: vacancy.isRemote ? "network" : "mappin.circle.fill")
                                .font(.caption)
                            Text(vacancy.location)
                                .font(.caption)
                        }
                        .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Text(timeAgo(from: vacancy.postedDate))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Text(vacancy.title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .lineLimit(2)
                
                HStack(spacing: Layout.salaryRowSpacing) {
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
                
                if !vacancy.tags.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: Layout.tagsScrollSpacing) {
                            ForEach(vacancy.tags.prefix(Layout.maxVisibleTags), id: \.self) { tag in
                                Text(tag)
                                    .font(.caption)
                                    .padding(.horizontal, Layout.tagChipHorizontalPadding)
                                    .padding(.vertical, Layout.tagChipVerticalPadding)
                                    .background(Color.blue.opacity(Layout.tagChipBackgroundOpacity))
                                    .foregroundColor(.blue)
                                    .cornerRadius(Layout.tagChipCornerRadius)
                            }
                        }
                    }
                }

                HStack {
                    Image(systemName: employmentTypeIcon)
                        .font(.caption)
                    Text(vacancy.employmentType.displayName)
                        .font(.caption)
                    
                    Spacer()
                    
                    if let deadline = vacancy.applicationDeadline {
                        HStack(spacing: Layout.deadlineRowSpacing) {
                            Image(systemName: "clock.fill")
                                .font(.caption2)
                            Text("до \(formatDate(deadline))")
                                .font(.caption2)
                        }
                        .foregroundColor(.red.opacity(Layout.deadlineForegroundOpacity))
                    }
                }
                .foregroundColor(.secondary)
            }
            .padding(Layout.contentPadding)
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

extension VacancyCardView {
    enum Layout {
        static let mainVStackSpacing: CGFloat = 12
        static let headerHStackSpacing: CGFloat = 12
        static let avatarSize: CGFloat = 48
        static let avatarPlaceholderOpacity: Double = 0.2
        static let companyBlockVStackSpacing: CGFloat = 4
        static let locationRowSpacing: CGFloat = 4
        static let salaryRowSpacing: CGFloat = 16
        static let maxVisibleTags: Int = 5
        static let tagsScrollSpacing: CGFloat = 8
        static let tagChipHorizontalPadding: CGFloat = 10
        static let tagChipVerticalPadding: CGFloat = 4
        static let tagChipBackgroundOpacity: Double = 0.1
        static let tagChipCornerRadius: CGFloat = 8
        static let deadlineRowSpacing: CGFloat = 4
        static let deadlineForegroundOpacity: Double = 0.8
        static let contentPadding: CGFloat = 16
        static let cornerRadius: CGFloat = 16
        static let shadowOpacity: Double = 0.05
        static let shadowRadius: CGFloat = 8
        static let shadowOffsetX: CGFloat = 0
        static let shadowOffsetY: CGFloat = 2
        static let borderOpacity: Double = 0.1
        static let borderLineWidth: CGFloat = 1
        static let previewVStackSpacing: CGFloat = 16
    }
}

#if DEBUG
struct VacancyCardView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: VacancyCardView.Layout.previewVStackSpacing) {
            VacancyCardView(vacancy: .mock1)
            VacancyCardView(vacancy: .mock2)
            VacancyCardView(vacancy: .mock3)
        }
        .padding()
        .background(Color(.systemGroupedBackground))
    }
}
#endif
