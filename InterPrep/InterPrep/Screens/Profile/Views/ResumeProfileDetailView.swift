//
//  ResumeProfileDetailView.swift
//  InterPrep
//
//  Просмотр загруженного резюме (профиль из API)
//

import SwiftUI
import DesignSystem
import NetworkService

struct ResumeProfileDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var profile: User_ResumeProfile?
    @State private var isLoading = true
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.2)
                            .tint(.brandPrimary)
                        Text("Загрузка резюме...")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let error = errorMessage {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                            .foregroundColor(.orange)
                        Text(error)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let profile = profile {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            if !profile.targetRoles.isEmpty {
                                section(title: "Целевые роли", items: profile.targetRoles)
                            }
                            if profile.hasExperienceLevel && !profile.experienceLevel.isEmpty {
                                section(title: "Уровень опыта", text: profile.experienceLevel)
                            }
                            if !profile.areas.isEmpty {
                                section(title: "Регионы", items: profile.areas.map { $0.name })
                            }
                            if profile.hasSalaryMin && profile.salaryMin > 0 {
                                let currency = profile.currency.isEmpty ? "₽" : profile.currency
                                section(title: "Зарплатные ожидания", text: "от \(Int(profile.salaryMin)) \(currency)")
                            }
                            if !profile.workFormat.isEmpty {
                                section(title: "Формат работы", items: profile.workFormat)
                            }
                            if !profile.skillsTop.isEmpty {
                                section(title: "Ключевые навыки", items: profile.skillsTop)
                            }
                            if profile.hasEducationLevel && !profile.educationLevel.isEmpty {
                                section(title: "Образование", text: profile.educationLevel)
                            }
                            if profile.hasNotes && !profile.notes.isEmpty {
                                section(title: "Дополнительно", text: profile.notes)
                            }
                            if profile.targetRoles.isEmpty && !profile.hasExperienceLevel && profile.areas.isEmpty &&
                                !profile.hasSalaryMin && profile.workFormat.isEmpty && profile.skillsTop.isEmpty &&
                                !profile.hasEducationLevel && !profile.hasNotes {
                                Text("Данные резюме пока не заполнены")
                                    .font(.body)
                                    .foregroundColor(.secondary)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                            }
                        }
                        .padding()
                    }
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Моё резюме")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Закрыть") {
                        dismiss()
                    }
                }
            }
            .task {
                await loadProfile()
            }
        }
    }
    
    private func loadProfile() async {
        isLoading = true
        errorMessage = nil
        let result = await NetworkServiceV2.shared.getUser_ResumeProfile()
        isLoading = false
        switch result {
        case .success(let response):
            if response.hasProfile {
                profile = response.profile
            } else {
                profile = nil
                errorMessage = "Резюме не найдено"
            }
        case .failure(let error):
            errorMessage = error.localizedDescription
        }
    }
    
    @ViewBuilder
    private func section(title: String, text: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
            Text(text)
                .font(.body)
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(12)
    }
    
    @ViewBuilder
    private func section(title: String, items: [String]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
            FlowLayout(spacing: 8) {
                ForEach(items, id: \.self) { item in
                    Text(item)
                        .font(.caption)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.brandPrimary.opacity(0.12))
                        .foregroundColor(.brandPrimary)
                        .cornerRadius(8)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(12)
    }
}

// Простой flow layout для тегов
private struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x, y: bounds.minY + result.positions[index].y), proposal: .unspecified)
        }
    }
    
    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth && x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }
        let totalHeight = y + rowHeight
        return (CGSize(width: maxWidth, height: totalHeight), positions)
    }
}

#if DEBUG
#Preview {
    ResumeProfileDetailView()
}
#endif
