//
//  AuthResumeProfileReviewView.swift
//  InterPrep
//
//  Profile review view for auth flow after resume upload
//

import DesignSystem
import NetworkService
import SwiftUI

// swiftlint:disable:next type_body_length
struct AuthResumeProfileReviewView: View {
    let onConfirm: () -> Void
    let onBack: () -> Void
    
    @State private var profile: User_ResumeProfile?
    @State private var status: User_ResumeProfileStatus = .draft
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var isEditing = false
    @State private var isSaving = false
    @State private var saveError: String?
    
    @State private var targetRolesText = ""
    @State private var experienceLevel = ""
    @State private var areasText = ""
    @State private var salaryMinText = ""
    @State private var currencyText = "₽"
    @State private var workFormatText = ""
    @State private var skillsTopText = ""
    @State private var educationLevel = ""
    @State private var notesText = ""
    
    var body: some View {
        ZStack {
            LinearGradient.brandBackground
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                header
                
                if isLoading {
                    loadingView
                } else if let error = errorMessage {
                    errorView(error)
                } else if isEditing {
                    editForm
                } else if let profile = profile {
                    profileContent(profile: profile)
                }
            }
        }
        .task {
            await loadProfile()
        }
    }
    
    @ViewBuilder
    private var header: some View {
        HStack {
            Button {
                if isEditing {
                    isEditing = false
                    saveError = nil
                } else {
                    onBack()
                }
            } label: {
                Image(systemName: isEditing ? "xmark" : "chevron.left")
                    .font(.title2)
                    .foregroundColor(.white)
                    .padding()
            }
            
            Spacer()
            
            Text(isEditing ? "Редактирование" : "Проверьте данные")
                .font(.headline)
                .foregroundColor(.white)
            
            Spacer()
            
            if !isLoading && errorMessage == nil && profile != nil {
                Button {
                    if isEditing {
                        Task { await saveProfile() }
                    } else {
                        copyProfileToEditState()
                        isEditing = true
                        saveError = nil
                    }
                } label: {
                    Text(isEditing ? "Сохранить" : "Изменить")
                        .font(.subheadline)
                        .foregroundColor(.white)
                        .padding()
                }
                .disabled(isSaving)
            } else {
                Color.clear
                    .frame(width: 80)
            }
        }
    }
    
    @ViewBuilder
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
                .tint(.white)
            Text("Загружаем данные резюме...")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    @ViewBuilder
    private func errorView(_ error: String) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 60))
                .foregroundColor(.yellow)
            
            Text(error)
                .font(.body)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button {
                Task { await loadProfile() }
            } label: {
                Text("Повторить")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.white)
                    .foregroundColor(.brandPrimary)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 32)
            
            Button {
                onConfirm()
            } label: {
                Text("Пропустить")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    @ViewBuilder
    private var editForm: some View {
        ScrollView {
            VStack(spacing: 16) {
                if let err = saveError {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                        Text(err)
                            .font(.subheadline)
                            .foregroundColor(.red)
                    }
                    .padding()
                    .background(Color.red.opacity(0.2))
                    .cornerRadius(12)
                }
                
                editSection(title: "Целевые роли", placeholder: "iOS Developer, Team Lead", text: $targetRolesText)
                editSection(title: "Уровень опыта", placeholder: "Junior / Middle / Senior / Lead", text: $experienceLevel)
                editSection(title: "Регионы", placeholder: "Москва, Санкт-Петербург", text: $areasText)
                
                HStack(spacing: 12) {
                    editSection(title: "Зарплата от", placeholder: "150000", text: $salaryMinText, keyboardType: .decimalPad)
                    editSection(title: "Валюта", placeholder: "₽", text: $currencyText)
                        .frame(width: 80)
                }
                
                editSection(title: "Формат работы", placeholder: "Удалённо, Офис, Гибрид", text: $workFormatText)
                editSection(title: "Ключевые навыки", placeholder: "Swift, UIKit, SwiftUI", text: $skillsTopText)
                editSection(title: "Образование", placeholder: "Высшее", text: $educationLevel)
                editSection(title: "Дополнительно", placeholder: "Заметки", text: $notesText)
            }
            .padding()
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
    
    @ViewBuilder
    private func editSection(
        title: String,
        placeholder: String,
        text: Binding<String>,
        keyboardType: UIKeyboardType = .default
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
            
            TextField(placeholder, text: text, axis: .vertical)
                .font(.body)
                .padding()
                .background(Color.white.opacity(0.15))
                .cornerRadius(12)
                .foregroundColor(.white)
                .keyboardType(keyboardType)
                .lineLimit(1...4)
        }
    }
    
    @ViewBuilder
    private func profileContent(profile: User_ResumeProfile) -> some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    statusBanner
                    
                    Text("Мы распознали следующие данные из вашего резюме.\nПроверьте и подтвердите их.")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.leading)
                        .padding(.bottom, 8)
                    
                    if !profile.targetRoles.isEmpty {
                        profileSection(title: "Целевые роли", items: profile.targetRoles)
                    }
                    if profile.hasExperienceLevel && !profile.experienceLevel.isEmpty {
                        profileSection(title: "Уровень опыта", text: profile.experienceLevel)
                    }
                    if !profile.areas.isEmpty {
                        profileSection(title: "Регионы", items: profile.areas.map { $0.name })
                    }
                    if profile.hasSalaryMin && profile.salaryMin > 0 {
                        let currency = profile.currency.isEmpty ? "₽" : profile.currency
                        profileSection(title: "Зарплатные ожидания", text: "от \(Int(profile.salaryMin)) \(currency)")
                    }
                    if !profile.workFormat.isEmpty {
                        profileSection(title: "Формат работы", items: profile.workFormat)
                    }
                    if !profile.skillsTop.isEmpty {
                        profileSection(title: "Ключевые навыки", items: profile.skillsTop)
                    }
                    if profile.hasEducationLevel && !profile.educationLevel.isEmpty {
                        profileSection(title: "Образование", text: profile.educationLevel)
                    }
                    if profile.hasNotes && !profile.notes.isEmpty {
                        profileSection(title: "Дополнительно", text: profile.notes)
                    }
                    
                    if isProfileEmpty(profile) {
                        emptyProfileView
                    }
                }
                .padding()
            }
            
            bottomButton
        }
    }
    
    @ViewBuilder
    private var statusBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "pencil.circle.fill")
                .font(.title3)
                .foregroundColor(.orange)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Данные из резюме")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Text("Проверьте правильность и подтвердите")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Spacer()
        }
        .padding()
        .background(Color.white.opacity(0.15))
        .cornerRadius(12)
    }
    
    @ViewBuilder
    private var emptyProfileView: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text.fill")
                .font(.system(size: 40))
                .foregroundColor(.white.opacity(0.5))
            
            Text("Не удалось распознать данные из резюме")
                .font(.body)
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
            
            Text("Вы можете заполнить профиль вручную")
                .font(.caption)
                .foregroundColor(.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }
    
    @ViewBuilder
    private var bottomButton: some View {
        VStack(spacing: 12) {
            Button {
                Task { await confirmProfile() }
            } label: {
                Text("Подтвердить и продолжить")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(Color.white)
                    .foregroundColor(.brandPrimary)
                    .cornerRadius(16)
            }
            
            Button {
                copyProfileToEditState()
                isEditing = true
            } label: {
                Text("Редактировать данные")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 32)
    }
    
    @ViewBuilder
    private func profileSection(title: String, text: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
            Text(text)
                .font(.body)
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(12)
    }
    
    @ViewBuilder
    private func profileSection(title: String, items: [String]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
            
            FlowLayoutAuth(spacing: 8) {
                ForEach(items, id: \.self) { item in
                    Text(item)
                        .font(.caption)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.white.opacity(0.2))
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(12)
    }
    
    private func isProfileEmpty(_ profile: User_ResumeProfile) -> Bool {
        profile.targetRoles.isEmpty &&
        !profile.hasExperienceLevel &&
        profile.areas.isEmpty &&
        !profile.hasSalaryMin &&
        profile.workFormat.isEmpty &&
        profile.skillsTop.isEmpty &&
        !profile.hasEducationLevel &&
        !profile.hasNotes
    }
    
    private func copyProfileToEditState() {
        guard let currentProfile = profile else { return }
        targetRolesText = currentProfile.targetRoles.joined(separator: ", ")
        experienceLevel = currentProfile.hasExperienceLevel ? currentProfile.experienceLevel : ""
        areasText = currentProfile.areas.map { $0.name }.joined(separator: ", ")
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
    
    private func loadProfile() async {
        isLoading = true
        errorMessage = nil
        
        let result = await NetworkServiceV2.shared.getUser_ResumeProfile()
        isLoading = false
        
        switch result {
        case .success(let response):
            status = response.status
            if response.hasProfile {
                profile = response.profile
            } else {
                profile = User_ResumeProfile()
            }
        case .failure(let error):
            errorMessage = error.localizedDescription
        }
    }
    
    private func saveProfile() async {
        let getMeResult = await NetworkServiceV2.shared.getMe()
        guard case .success(let meResponse) = getMeResult else {
            saveError = "Не удалось определить пользователя"
            return
        }
        
        isSaving = true
        saveError = nil
        let updated = buildProfileFromEditState()
        let result = await NetworkServiceV2.shared.updateUser_ResumeProfile(
            userId: meResponse.user.id,
            profile: updated
        )
        isSaving = false
        
        switch result {
        case .success:
            profile = updated
            status = .confirmed
            isEditing = false
        case .failure(let error):
            saveError = error.localizedDescription
        }
    }
    
    private func confirmProfile() async {
        guard let currentProfile = profile else {
            onConfirm()
            return
        }
        
        let getMeResult = await NetworkServiceV2.shared.getMe()
        guard case .success(let meResponse) = getMeResult else {
            onConfirm()
            return
        }
        
        _ = await NetworkServiceV2.shared.updateUser_ResumeProfile(
            userId: meResponse.user.id,
            profile: currentProfile
        )
        
        onConfirm()
    }
    
    private func buildProfileFromEditState() -> User_ResumeProfile {
        var profile = User_ResumeProfile()
        profile.targetRoles = splitTrim(targetRolesText)
        if !experienceLevel.isEmpty {
            profile.experienceLevel = experienceLevel.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        profile.areas = areasText
            .components(separatedBy: CharacterSet(charactersIn: ",\n"))
            .map { line in
                var area = User_Area()
                area.name = String(line).trimmingCharacters(in: .whitespaces)
                return area
            }
            .filter { !$0.name.isEmpty }
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
}

private struct FlowLayoutAuth: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, subview) in subviews.enumerated() {
            subview.place(
                at: CGPoint(x: bounds.minX + result.positions[index].x, y: bounds.minY + result.positions[index].y),
                proposal: .unspecified
            )
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

#Preview {
    AuthResumeProfileReviewView(
        onConfirm: {},
        onBack: {}
    )
}
