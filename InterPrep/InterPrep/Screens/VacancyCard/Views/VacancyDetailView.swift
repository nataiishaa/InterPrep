//
//  VacancyDetailView.swift
//  VacancyCardModule
//
//  Детальный вид вакансии
//

import SwiftUI

private let jobSearchStages = [
    "Отклик",
    "Резюме на рассмотрении",
    "Собеседование",
    "Тестовое задание",
    "Оффер"
]

public struct VacancyDetailView: View {
    let vacancy: Vacancy
    let currentStageIndex: Int
    let onApply: () -> Void
    let onSave: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    public init(
        vacancy: Vacancy,
        currentStageIndex: Int = 0,
        onApply: @escaping () -> Void = {},
        onSave: @escaping () -> Void = {}
    ) {
        self.vacancy = vacancy
        self.currentStageIndex = min(max(currentStageIndex, 0), jobSearchStages.count - 1)
        self.onApply = onApply
        self.onSave = onSave
    }
    
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Layout.rootVStackSpacing) {
                headerSection
                
                Divider()
                
                timelineSection
                
                Divider()
                
                infoSection
                
                Divider()

                descriptionSection
                
                if !vacancy.requirements.isEmpty {
                    requirementsSection
                }
                
                if !vacancy.benefits.isEmpty {
                    benefitsSection
                }
                
                if !vacancy.tags.isEmpty {
                    tagsSection
                }
            }
            .padding()
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: onSave) {
                    Image(systemName: "bookmark")
                        .foregroundColor(.blue)
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            applyButton
        }
    }
    
    // MARK: - Sections
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: Layout.headerVStackSpacing) {
            HStack(spacing: Layout.headerAvatarRowSpacing) {
                Circle()
                    .fill(Color.gray.opacity(Layout.headerAvatarPlaceholderOpacity))
                    .frame(width: Layout.headerAvatarSize, height: Layout.headerAvatarSize)
                    .overlay(
                        Text(vacancy.company.prefix(1))
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.gray)
                    )
                
                VStack(alignment: .leading, spacing: Layout.headerMetaVStackSpacing) {
                    Text(vacancy.company)
                        .font(.title3)
                        .fontWeight(.semibold)
                    
                    HStack(spacing: Layout.headerLocationHStackSpacing) {
                        Image(systemName: vacancy.isRemote ? "network" : "mappin.circle.fill")
                            .font(.subheadline)
                        Text(vacancy.location)
                            .font(.subheadline)
                    }
                    .foregroundColor(.secondary)
                }
            }
            
            Text(vacancy.title)
                .font(.title)
                .fontWeight(.bold)
            
            Text("Опубликовано \(formatFullDate(vacancy.postedDate))")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private var timelineSection: some View {
        VStack(alignment: .leading, spacing: Layout.timelineOuterSpacing) {
            Text("Этапы поиска")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: Layout.timelineInnerVStackSpacing) {
                ForEach(Array(jobSearchStages.enumerated()), id: \.offset) { index, stageName in
                    HStack(alignment: .top, spacing: Layout.timelineRowHStackSpacing) {
                        VStack(spacing: Layout.timelineInnerVStackSpacing) {
                            Circle()
                                .fill(index <= currentStageIndex ? Color.blue : Color.gray.opacity(Layout.timelineInactiveDotOpacity))
                                .frame(width: Layout.timelineDotSize, height: Layout.timelineDotSize)
                            
                            if index < jobSearchStages.count - 1 {
                                Rectangle()
                                    .fill(index < currentStageIndex ? Color.blue.opacity(Layout.timelineConnectorActiveOpacity) : Color.gray.opacity(Layout.timelineConnectorInactiveOpacity))
                                    .frame(width: Layout.timelineConnectorWidth)
                                    .frame(minHeight: Layout.timelineConnectorMinHeight)
                            }
                        }
                        .frame(width: Layout.timelineRailWidth)
                        
                        VStack(alignment: .leading, spacing: Layout.timelineTextVStackSpacing) {
                            Text(stageName)
                                .font(index == currentStageIndex ? .subheadline.weight(.semibold) : .subheadline)
                                .foregroundColor(index == currentStageIndex ? .primary : .secondary)
                            
                            if index == currentStageIndex {
                                Text("Удачи!")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.blue)
                            }
                        }
                        .padding(.bottom, index < jobSearchStages.count - 1 ? Layout.timelineStageBottomPadding : Layout.timelineStageBottomPaddingNone)
                        
                        Spacer(minLength: Layout.timelineSpacerMinLength)
                    }
                }
            }
        }
    }
    
    private var infoSection: some View {
        VStack(spacing: Layout.infoSectionSpacing) {
            if let salary = vacancy.salary {
                InfoRow(
                    icon: "rublesign.circle.fill",
                    iconColor: .green,
                    title: "Зарплата",
                    value: salary.formatted + " " + salary.period.displayName
                )
            }
            
            InfoRow(
                icon: "star.fill",
                iconColor: .orange,
                title: "Опыт",
                value: vacancy.experienceLevel.displayName
            )
            
            InfoRow(
                icon: "briefcase.fill",
                iconColor: .blue,
                title: "Тип занятости",
                value: vacancy.employmentType.displayName
            )
            
            if vacancy.isRemote {
                InfoRow(
                    icon: "network",
                    iconColor: .purple,
                    title: "Формат",
                    value: "Удалённая работа"
                )
            }
            
            if let deadline = vacancy.applicationDeadline {
                InfoRow(
                    icon: "clock.fill",
                    iconColor: .red,
                    title: "Дедлайн",
                    value: formatFullDate(deadline)
                )
            }
        }
    }
    
    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: Layout.sectionTitleBlockSpacing) {
            Text("Описание")
                .font(.headline)
                .fontWeight(.semibold)
            
            Text(vacancy.description)
                .font(.body)
                .foregroundColor(.secondary)
        }
    }
    
    private var requirementsSection: some View {
        VStack(alignment: .leading, spacing: Layout.sectionTitleBlockSpacing) {
            Text("Требования")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: Layout.listBlockSpacing) {
                ForEach(vacancy.requirements, id: \.self) { requirement in
                    HStack(alignment: .top, spacing: Layout.listItemRowSpacing) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.caption)
                        Text(requirement)
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }
    
    private var benefitsSection: some View {
        VStack(alignment: .leading, spacing: Layout.sectionTitleBlockSpacing) {
            Text("Условия")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: Layout.listBlockSpacing) {
                ForEach(vacancy.benefits, id: \.self) { benefit in
                    HStack(alignment: .top, spacing: Layout.listItemRowSpacing) {
                        Image(systemName: "star.fill")
                            .foregroundColor(.orange)
                            .font(.caption)
                        Text(benefit)
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }
    
    private var tagsSection: some View {
        VStack(alignment: .leading, spacing: Layout.sectionTitleBlockSpacing) {
            Text("Навыки")
                .font(.headline)
                .fontWeight(.semibold)
            
            FlowLayout(spacing: Layout.tagFlowSpacing) {
                ForEach(vacancy.tags, id: \.self) { tag in
                    Text(tag)
                        .font(.subheadline)
                        .padding(.horizontal, Layout.tagChipHorizontalPadding)
                        .padding(.vertical, Layout.tagChipVerticalPadding)
                        .background(Color.blue.opacity(Layout.tagChipBackgroundOpacity))
                        .foregroundColor(.blue)
                        .cornerRadius(Layout.tagChipCornerRadius)
                }
            }
        }
    }
    
    private var applyButton: some View {
        Button(action: onApply) {
            Text("Откликнуться")
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .cornerRadius(Layout.applyButtonCornerRadius)
        }
        .padding()
        .background(Color(.systemBackground))
        .shadow(
            color: Color.black.opacity(Layout.applyBarShadowOpacity),
            radius: Layout.applyBarShadowRadius,
            x: Layout.applyBarShadowOffsetX,
            y: Layout.applyBarShadowOffsetY
        )
    }
    
    // MARK: - Helpers
    
    private func formatFullDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: "ru_RU")
        return formatter.string(from: date)
    }
}

extension VacancyDetailView {
    enum Layout {
        static let rootVStackSpacing: CGFloat = 24

        static let headerVStackSpacing: CGFloat = 12
        static let headerAvatarRowSpacing: CGFloat = 12
        static let headerAvatarSize: CGFloat = 60
        static let headerAvatarPlaceholderOpacity: Double = 0.2
        static let headerMetaVStackSpacing: CGFloat = 4
        static let headerLocationHStackSpacing: CGFloat = 4

        static let timelineOuterSpacing: CGFloat = 16
        static let timelineInnerVStackSpacing: CGFloat = 0
        static let timelineRowHStackSpacing: CGFloat = 12
        static let timelineDotSize: CGFloat = 12
        static let timelineInactiveDotOpacity: Double = 0.3
        static let timelineConnectorWidth: CGFloat = 2
        static let timelineConnectorActiveOpacity: Double = 0.5
        static let timelineConnectorInactiveOpacity: Double = 0.2
        static let timelineConnectorMinHeight: CGFloat = 28
        static let timelineRailWidth: CGFloat = 12
        static let timelineTextVStackSpacing: CGFloat = 4
        static let timelineStageBottomPadding: CGFloat = 8
        static let timelineStageBottomPaddingNone: CGFloat = 0
        static let timelineSpacerMinLength: CGFloat = 0

        static let infoSectionSpacing: CGFloat = 16
        static let sectionTitleBlockSpacing: CGFloat = 12
        static let listBlockSpacing: CGFloat = 8
        static let listItemRowSpacing: CGFloat = 8

        static let tagFlowSpacing: CGFloat = 8
        static let tagChipHorizontalPadding: CGFloat = 12
        static let tagChipVerticalPadding: CGFloat = 6
        static let tagChipBackgroundOpacity: Double = 0.1
        static let tagChipCornerRadius: CGFloat = 12

        static let applyButtonCornerRadius: CGFloat = 16
        static let applyBarShadowOpacity: Double = 0.1
        static let applyBarShadowRadius: CGFloat = 10
        static let applyBarShadowOffsetX: CGFloat = 0
        static let applyBarShadowOffsetY: CGFloat = -5

        static let infoRowHStackSpacing: CGFloat = 12
        static let infoRowIconWidth: CGFloat = 24
        static let infoRowTitleValueSpacing: CGFloat = 2
    }
}

// MARK: - Info Row

private struct InfoRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let value: String
    
    var body: some View {
        HStack(spacing: VacancyDetailView.Layout.infoRowHStackSpacing) {
            Image(systemName: icon)
                .foregroundColor(iconColor)
                .frame(width: VacancyDetailView.Layout.infoRowIconWidth)
            
            VStack(alignment: .leading, spacing: VacancyDetailView.Layout.infoRowTitleValueSpacing) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.body)
                    .fontWeight(.medium)
            }
            
            Spacer()
        }
    }
}

// MARK: - Flow Layout

private struct FlowLayout: Layout {
    var spacing: CGFloat = VacancyDetailView.Layout.tagFlowSpacing
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.width ?? 0, subviews: subviews, spacing: spacing)
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x, y: bounds.minY + result.positions[index].y), proposal: .unspecified)
        }
    }
    
    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []
        
        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var lineHeight: CGFloat = 0
            
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                
                if x + size.width > maxWidth && x > 0 {
                    x = 0
                    y += lineHeight + spacing
                    lineHeight = 0
                }
                
                positions.append(CGPoint(x: x, y: y))
                lineHeight = max(lineHeight, size.height)
                x += size.width + spacing
            }
            
            self.size = CGSize(width: maxWidth, height: y + lineHeight)
        }
    }
}

// MARK: - Preview

#if DEBUG
struct VacancyDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            VacancyDetailView(vacancy: .mock1)
        }
    }
}
#endif
