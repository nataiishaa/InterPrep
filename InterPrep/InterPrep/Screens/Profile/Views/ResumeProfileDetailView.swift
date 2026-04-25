//
//  ResumeProfileDetailView.swift
//  InterPrep
//
//  Просмотр и редактирование резюме (профиль из API)
//

import DesignSystem
import NetworkService
import SwiftUI

// swiftlint:disable:next type_body_length
struct ResumeProfileDetailView: View {
    var userId: String?
    var onUploadNewResume: (() -> Void)?
    @Environment(\.dismiss) private var dismiss
    @State private var profile: User_ResumeProfile?
    @State private var sourceMaterialId: String?
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var isEditing = false
    @State private var isSaving = false
    @State private var saveError: String?
    
    // Редактируемые поля (комма/перенос строки — разделители списков)
    @State private var targetRolesText = ""
    @State private var experienceLevel = ""
    @State private var areasText = ""
    @State private var salaryMinText = ""
    @State private var currencyText = "₽"
    @State private var workFormatText = ""
    @State private var skillsTopText = ""
    @State private var educationLevel = ""
    @State private var notesText = ""
    
    init(userId: String? = nil, onUploadNewResume: (() -> Void)? = nil) {
        self.userId = userId
        self.onUploadNewResume = onUploadNewResume
    }
    
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
                    VStack(spacing: 20) {
                        Image(systemName: "doc.text.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary.opacity(0.5))
                        
                        Text(error)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        if onUploadNewResume != nil {
                            Button {
                                if let callback = onUploadNewResume {
                                    callback()
                                    dismiss()
                                }
                            } label: {
                                HStack {
                                    Image(systemName: "arrow.up.doc.fill")
                                    Text("Загрузить резюме")
                                        .fontWeight(.medium)
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(Color.brandPrimary)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                            }
                            .padding(.horizontal, 32)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if isEditing {
                    editForm
                } else if let profile = profile {
                    readOnlyContent(profile: profile)
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Моё резюме")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(isEditing ? "Отмена" : "Закрыть") {
                        if isEditing {
                            isEditing = false
                            saveError = nil
                        } else {
                            dismiss()
                        }
                    }
                }
                if profile != nil && !isLoading && errorMessage == nil {
                    ToolbarItem(placement: .primaryAction) {
                        if isEditing {
                            Button("Сохранить") {
                                Task { await saveProfile() }
                            }
                            .disabled(isSaving)
                        } else {
                            Button("Редактировать") {
                                copyProfileToEditState()
                                isEditing = true
                                saveError = nil
                            }
                        }
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                if profile != nil && !isLoading && !isEditing {
                    uploadNewResumeButton
                }
            }
            .task {
                await loadProfile()
            }
        }
    }
    
    private var editForm: some View {
        Form {
            if let err = saveError {
                Section {
                    Text(err)
                        .foregroundColor(.red)
                        .font(.subheadline)
                }
            }
            Section("Целевые роли") {
                TextField("Например: iOS Developer, Team Lead", text: $targetRolesText, axis: .vertical)
                    .lineLimit(2...6)
            }
            Section("Уровень опыта") {
                TextField("Junior / Middle / Senior / Lead", text: $experienceLevel)
            }
            Section("Регионы") {
                TextField("Город или регион, с новой строки", text: $areasText, axis: .vertical)
                    .lineLimit(2...6)
            }
            Section("Зарплатные ожидания") {
                HStack {
                    TextField("От (число)", text: $salaryMinText)
                        .keyboardType(.decimalPad)
                    TextField("₽", text: $currencyText)
                        .frame(width: 50)
                }
            }
            Section("Формат работы") {
                TextField("Удалённо, Офис, Гибрид — через запятую", text: $workFormatText, axis: .vertical)
                    .lineLimit(2...4)
            }
            Section("Ключевые навыки") {
                TextField("Через запятую или с новой строки", text: $skillsTopText, axis: .vertical)
                    .lineLimit(3...8)
            }
            Section("Образование") {
                TextField("Уровень или вуз", text: $educationLevel)
            }
            Section("Дополнительно") {
                TextField("Заметки", text: $notesText, axis: .vertical)
                    .lineLimit(3...8)
            }
        }
        .overlay {
            if isSaving {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                ProgressView()
                    .scaleEffect(1.2)
                    .tint(.white)
            }
        }
    }
    
    private func readOnlyContent(profile: User_ResumeProfile) -> some View {
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
                    emptyStateView
                }
            }
            .padding()
        }
    }
    
    @ViewBuilder
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text.fill")
                .font(.system(size: 60))
                .foregroundColor(.secondary.opacity(0.5))
            
            Text("Данные резюме пока не заполнены")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Text("Загрузите файл резюме или заполните форму вручную")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }
    
    @ViewBuilder
    private var uploadNewResumeButton: some View {
        VStack(spacing: 0) {
            Divider()
            Button {
                if let callback = onUploadNewResume {
                    callback()
                    dismiss()
                }
            } label: {
                HStack {
                    Image(systemName: "arrow.up.doc.fill")
                        .font(.body)
                    Text("Загрузить новое резюме")
                        .font(.body)
                        .fontWeight(.medium)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Color(.systemBackground))
                .foregroundColor(.brandPrimary)
            }
        }
        .background(Color(.systemBackground))
    }
    
    private func copyProfileToEditState() {
        guard let currentProfile = profile else { return }
        targetRolesText = currentProfile.targetRoles.joined(separator: ", ")
        experienceLevel = currentProfile.hasExperienceLevel ? currentProfile.experienceLevel : ""
        areasText = currentProfile.areas.map { $0.name }.joined(separator: "\n")
        if currentProfile.hasSalaryMin && currentProfile.salaryMin > 0 {
            salaryMinText = String(Int(currentProfile.salaryMin))
        } else {
            salaryMinText = ""
        }
        currencyText = currentProfile.hasCurrency && !currentProfile.currency.isEmpty ? currentProfile.currency : "₽"
        workFormatText = currentProfile.workFormat.joined(separator: ", ")
        skillsTopText = currentProfile.skillsTop.joined(separator: ", ")
        educationLevel = currentProfile.hasEducationLevel ? currentProfile.educationLevel : ""
        notesText = currentProfile.hasNotes ? currentProfile.notes : ""
    }
    
    private func saveProfile() async {
        guard let uidString = userId, let uid = UInt32(uidString), uid > 0 else {
            saveError = "Не удалось определить пользователя"
            return
        }
        isSaving = true
        saveError = nil
        let updated = buildProfileFromEditState()
        let result = await NetworkServiceV2.shared.updateUser_ResumeProfile(userId: uid, profile: updated)
        isSaving = false
        switch result {
        case .success:
            profile = updated
            isEditing = false
        case .failure(let error):
            saveError = error.localizedDescription
        }
    }
    
    private func buildProfileFromEditState() -> User_ResumeProfile {
        var profile = User_ResumeProfile()
        profile.targetRoles = splitTrim(targetRolesText)
        if !experienceLevel.isEmpty {
            profile.experienceLevel = experienceLevel.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        profile.areas = areasText
            .split(separator: "\n", omittingEmptySubsequences: true)
            .map { line in
                var area = User_Area()
                area.name = String(line).trimmingCharacters(in: .whitespaces)
                return area
            }
        if let salary = Double(salaryMinText.trimmingCharacters(in: .whitespaces)), salary > 0 {
            profile.salaryMin = salary
        }
        if !currencyText.isEmpty {
            profile.currency = currencyText.trimmingCharacters(in: .whitespaces)
        }
        profile.workFormat = splitTrim(workFormatText)
        profile.skillsTop = splitTrim(skillsTopText)
        if !educationLevel.isEmpty {
            profile.educationLevel = educationLevel.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        if !notesText.isEmpty {
            profile.notes = notesText.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return profile
    }
    
    private func splitTrim(_ text: String) -> [String] {
        text.components(separatedBy: CharacterSet(charactersIn: ",\n"))
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
    
    private func loadProfile() async {
        isLoading = true
        errorMessage = nil
        let result = await NetworkServiceV2.shared.getUser_ResumeProfile()
        isLoading = false
        switch result {
        case .success(let response):
            sourceMaterialId = response.hasSourceMaterialID ? response.sourceMaterialID : nil
            
            if response.hasProfile {
                profile = response.profile
            } else if response.hasSourceMaterialID && !response.sourceMaterialID.isEmpty {
                profile = User_ResumeProfile()
            } else {
                profile = nil
                errorMessage = "Резюме не найдено. Загрузите файл резюме или заполните данные вручную."
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
