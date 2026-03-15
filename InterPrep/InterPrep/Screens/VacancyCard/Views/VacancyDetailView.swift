//
//  VacancyDetailView.swift
//  VacancyCardModule
//
//  Детальный вид вакансии
//

import SwiftUI

/// Этапы поиска работы для таймлайна
private let jobSearchStages = [
    "Отклик",
    "Резюме на рассмотрении",
    "Собеседование",
    "Тестовое задание",
    "Оффер"
]

public struct VacancyDetailView: View {
    let vacancy: Vacancy
    /// Индекс текущего этапа (0 — отклик, 1 — резюме, 2 — собеседование, 3 — тестовое, 4 — оффер)
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
            VStack(alignment: .leading, spacing: 24) {
                // Header
                headerSection
                
                Divider()
                
                // Timeline + Удачи на текущем этапе
                timelineSection
                
                Divider()
                
                // Salary & Info
                infoSection
                
                Divider()
                
                // Description
                descriptionSection
                
                // Requirements
                if !vacancy.requirements.isEmpty {
                    requirementsSection
                }
                
                // Benefits
                if !vacancy.benefits.isEmpty {
                    benefitsSection
                }
                
                // Tags
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
        VStack(alignment: .leading, spacing: 12) {
            // Company
            HStack(spacing: 12) {
                Circle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 60, height: 60)
                    .overlay(
                        Text(vacancy.company.prefix(1))
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.gray)
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(vacancy.company)
                        .font(.title3)
                        .fontWeight(.semibold)
                    
                    HStack(spacing: 4) {
                        Image(systemName: vacancy.isRemote ? "network" : "mappin.circle.fill")
                            .font(.subheadline)
                        Text(vacancy.location)
                            .font(.subheadline)
                    }
                    .foregroundColor(.secondary)
                }
            }
            
            // Job Title
            Text(vacancy.title)
                .font(.title)
                .fontWeight(.bold)
            
            // Posted Date
            Text("Опубликовано \(formatFullDate(vacancy.postedDate))")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private var timelineSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Этапы поиска")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 0) {
                ForEach(Array(jobSearchStages.enumerated()), id: \.offset) { index, stageName in
                    HStack(alignment: .top, spacing: 12) {
                        // Вертикальная линия + точка
                        VStack(spacing: 0) {
                            Circle()
                                .fill(index <= currentStageIndex ? Color.blue : Color.gray.opacity(0.3))
                                .frame(width: 12, height: 12)
                            
                            if index < jobSearchStages.count - 1 {
                                Rectangle()
                                    .fill(index < currentStageIndex ? Color.blue.opacity(0.5) : Color.gray.opacity(0.2))
                                    .frame(width: 2)
                                    .frame(minHeight: 28)
                            }
                        }
                        .frame(width: 12)
                        
                        VStack(alignment: .leading, spacing: 4) {
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
                        .padding(.bottom, index < jobSearchStages.count - 1 ? 8 : 0)
                        
                        Spacer(minLength: 0)
                    }
                }
            }
        }
    }
    
    private var infoSection: some View {
        VStack(spacing: 16) {
            // Salary
            if let salary = vacancy.salary {
                InfoRow(
                    icon: "rublesign.circle.fill",
                    iconColor: .green,
                    title: "Зарплата",
                    value: salary.formatted + " " + salary.period.displayName
                )
            }
            
            // Experience
            InfoRow(
                icon: "star.fill",
                iconColor: .orange,
                title: "Опыт",
                value: vacancy.experienceLevel.displayName
            )
            
            // Employment Type
            InfoRow(
                icon: "briefcase.fill",
                iconColor: .blue,
                title: "Тип занятости",
                value: vacancy.employmentType.displayName
            )
            
            // Remote
            if vacancy.isRemote {
                InfoRow(
                    icon: "network",
                    iconColor: .purple,
                    title: "Формат",
                    value: "Удалённая работа"
                )
            }
            
            // Deadline
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
        VStack(alignment: .leading, spacing: 12) {
            Text("Описание")
                .font(.headline)
                .fontWeight(.semibold)
            
            Text(vacancy.description)
                .font(.body)
                .foregroundColor(.secondary)
        }
    }
    
    private var requirementsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Требования")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(vacancy.requirements, id: \.self) { requirement in
                    HStack(alignment: .top, spacing: 8) {
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
        VStack(alignment: .leading, spacing: 12) {
            Text("Условия")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(vacancy.benefits, id: \.self) { benefit in
                    HStack(alignment: .top, spacing: 8) {
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
        VStack(alignment: .leading, spacing: 12) {
            Text("Навыки")
                .font(.headline)
                .fontWeight(.semibold)
            
            FlowLayout(spacing: 8) {
                ForEach(vacancy.tags, id: \.self) { tag in
                    Text(tag)
                        .font(.subheadline)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue.opacity(0.1))
                        .foregroundColor(.blue)
                        .cornerRadius(12)
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
                .cornerRadius(16)
        }
        .padding()
        .background(Color(.systemBackground))
        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: -5)
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

// MARK: - Info Row

private struct InfoRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let value: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(iconColor)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
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
    var spacing: CGFloat = 8
    
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
