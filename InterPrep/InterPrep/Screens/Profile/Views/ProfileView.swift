//
//  ProfileView.swift
//  InterPrep
//
//  Profile screen with settings and statistics
//

import CalendarFeature
import DesignSystem
import NotificationService
import SwiftUI

// swiftlint:disable file_length
// swiftlint:disable:next type_body_length
struct ProfileView: View {
    let model: Model
    @StateObject private var notificationManager = NotificationManager.shared
    @State private var showEditProfile = false
    @State private var showCalDAVSettings = false
    @State private var showContactDevelopers = false
    @State private var showLogoutAlert = false
    @State private var showDeleteAccountSheet = false
    @State private var deletePassword = ""
    @State private var showNotificationAlert = false
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                profileHeader
                resumeSection
                statisticsSection
                settingsSection
                actionsSection
                aboutSection
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .safeAreaInset(edge: .bottom) {
            Color.clear.frame(height: 60)
        }
        .sheet(isPresented: $showEditProfile) {
            ProfileEditView(model: model.editModel)
        }
        .sheet(isPresented: $showCalDAVSettings) {
            CalDAVSettingsView(
                settings: CalDAVSettingsManager.shared.loadSettings(),
                onSave: { settings in
                    CalDAVSettingsManager.shared.saveSettings(settings)
                }
            )
        }
        .sheet(isPresented: $showContactDevelopers) {
            ProfileContactDevelopersView(onDismiss: { showContactDevelopers = false })
        }
        .alert("Выйти из аккаунта?", isPresented: $showLogoutAlert) {
            Button("Отмена", role: .cancel) {}
            Button("Выйти", role: .destructive) {
                model.onLogout()
            }
        } message: {
            Text("Вы сможете снова войти с тем же email и паролем.")
        }
        .sheet(isPresented: $showDeleteAccountSheet) {
            DeleteAccountSheet(
                password: $deletePassword,
                errorMessage: model.deleteAccountError,
                onConfirm: {
                    model.onDeleteAccount(deletePassword)
                },
                onDismiss: {
                    deletePassword = ""
                    model.onClearDeleteAccountError()
                    showDeleteAccountSheet = false
                }
            )
        }
        .alert("Разрешить уведомления?", isPresented: $showNotificationAlert) {
            Button("Отмена", role: .cancel) {}
            Button("Разрешить") {
                Task {
                    let granted = await notificationManager.requestAuthorization()
                    if granted {
                        model.onNotificationsToggled(true)
                    }
                }
            }
        } message: {
            Text("Приложение будет напоминать вам о предстоящих событиях и собеседованиях.")
        }
        .onAppear {
            Task {
                await notificationManager.checkAuthorizationStatus()
            }
        }
    }
    
    // MARK: - Profile Header
    
    @ViewBuilder
    private var profileHeader: some View {
        VStack(spacing: 16) {
            if model.isOfflineMode {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.clockwise.icloud")
                        .font(.caption)
                    Text("Данные из кеша")
                        .font(.caption)
                }
                .foregroundColor(.secondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(12)
            }
            
            ZStack(alignment: .bottomTrailing) {
                if let localURL = model.cachedProfilePhotoURL {
                    avatarImageFromURL(localURL)
                        .id(localURL)
                } else if let urlString = model.user?.avatarURL, !urlString.isEmpty, let url = URL(string: urlString) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                        case .failure, .empty:
                            avatarPlaceholder
                        @unknown default:
                            avatarPlaceholder
                        }
                    }
                    .frame(width: 100, height: 100)
                    .clipShape(Circle())
                } else {
                    avatarPlaceholder
                }
                
                Button {
                    model.onEditProfileTapped?()
                    showEditProfile = true
                } label: {
                    Image(systemName: "pencil.circle.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                        .background(
                            Circle()
                                .fill(Color.brandPrimary)
                                .frame(width: 32, height: 32)
                        )
                }
            }
            
            // Имя и почта (почта только просмотр)
            VStack(spacing: 4) {
                Text(model.user?.fullName ?? "Пользователь")
                    .font(.title2)
                    .fontWeight(.bold)
                
                if let position = model.user?.position, !position.isEmpty {
                    Text(position)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                if let email = model.user?.email, !email.isEmpty {
                    Text(email)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.cardBackground)
        .cornerRadius(16)
        .shadow(color: shadowColor, radius: 8, x: 0, y: 2)
    }
    
    @ViewBuilder
    private func avatarImageFromURL(_ url: URL) -> some View {
        // Strip query parameters for file path since they're only used for cache busting
        let filePath = url.path
        if let uiImage = UIImage(contentsOfFile: filePath) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
                .frame(width: 100, height: 100)
                .clipped()
                .clipShape(Circle())
        } else {
            avatarPlaceholder
        }
    }
    
    private var avatarPlaceholder: some View {
        Circle()
            .fill(
                LinearGradient(
                    colors: [.brandPrimary, .brandSecondary],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: 100, height: 100)
            .overlay(
                Text(model.user?.initials ?? "?")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundColor(.white)
            )
    }
    
    // MARK: - Resume Section
    
    @ViewBuilder
    private var resumeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Резюме")
                .font(.headline)
                .padding(.horizontal, 4)
            
            VStack(spacing: 0) {
                HStack(spacing: 12) {
                    Image(systemName: "doc.text.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                        .frame(width: 48, height: 48)
                        .background(
                            LinearGradient(
                                colors: [.brandPrimary, .brandSecondary],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .cornerRadius(12)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(model.hasResumeData ? "Ваше резюме загружено" : "Резюме не загружено")
                            .font(.body)
                            .fontWeight(.medium)
                        
                        Text(model.hasResumeData
                             ? "Посмотрите данные на основе которых мы предлагаем вам вакансии."
                             : "Загрузите резюме, чтобы мы могли подбирать подходящие вакансии.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                    
                    Spacer()
                }
                .padding()
                
                Divider()
                
                if model.hasResumeData {
                    Button {
                        model.onViewResume()
                    } label: {
                        HStack {
                            Image(systemName: "doc.text.magnifyingglass")
                                .font(.body)
                            Text("Посмотреть резюме")
                                .font(.body)
                                .fontWeight(.medium)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .foregroundColor(.primary)
                        .padding()
                    }
                    
                    Divider()
                }
                
                Button {
                    model.onChangeResume()
                } label: {
                    HStack {
                        Image(systemName: "arrow.up.doc.fill")
                            .font(.body)
                        Text(model.hasResumeData ? "Загрузить новое резюме" : "Загрузить резюме")
                            .font(.body)
                            .fontWeight(.medium)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .foregroundColor(.brandPrimary)
                    .padding()
                }
            }
            .background(Color.cardBackground)
            .cornerRadius(12)
            .shadow(color: shadowColor, radius: 4, x: 0, y: 2)
        }
    }
    
    // MARK: - Statistics Section (с бэкенда: запланировано / предстоит)
    
    @ViewBuilder
    private var statisticsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Статистика")
                .font(.headline)
                .padding(.horizontal, 4)
            
            HStack(spacing: 12) {
                StatCard(
                    title: "Собеседований запланировано",
                    value: "\(model.statistics.totalInterviews)",
                    icon: "calendar.badge.clock",
                    color: .blue
                )
                StatCard(
                    title: "Собеседований предстоит",
                    value: "\(model.statistics.upcomingInterviews)",
                    icon: "clock.arrow.circlepath",
                    color: .orange
                )
            }
        }
    }
    
    // MARK: - Settings Section
    
    @ViewBuilder
    private var settingsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Настройки")
                .font(.headline)
                .padding(.horizontal, 4)
            
            VStack(spacing: 0) {
                VStack(spacing: 0) {
                    SettingsRow(
                        icon: "bell.fill",
                        title: "Уведомления",
                        color: .red
                    ) {
                        Toggle("", isOn: Binding(
                            get: { model.settings.notificationsEnabled },
                            set: { newValue in
                                if newValue && !notificationManager.isAuthorized {
                                    showNotificationAlert = true
                                } else {
                                    model.onNotificationsToggled(newValue)
                                }
                            }
                        ))
                        .tint(.brandPrimary)
                    }
                    
                    if model.settings.notificationsEnabled && !notificationManager.isAuthorized {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.caption)
                                .foregroundColor(.orange)
                            
                            Text("Разрешите уведомления в настройках iOS")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Button("Открыть") {
                                notificationManager.openSettings()
                            }
                            .font(.caption)
                            .foregroundColor(.brandPrimary)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.orange.opacity(0.1))
                    }
                }
                
                Divider().padding(.leading, 52)
                
                SettingsRow(
                    icon: "paintbrush.fill",
                    title: "Тема",
                    color: .purple
                ) {
                    Menu {
                        ForEach(ProfileState.AppSettings.Theme.allCases, id: \.self) { theme in
                            Button(theme.rawValue) {
                                model.onThemeChanged(theme)
                            }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text(model.settings.theme.rawValue)
                                .foregroundColor(.secondary)
                            Image(systemName: "chevron.up.chevron.down")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Divider().padding(.leading, 52)
                
                SettingsRow(
                    icon: "calendar.badge.clock",
                    title: "Синхронизация с календарём",
                    color: .green
                ) {
                    Button {
                        showCalDAVSettings = true
                    } label: {
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .background(Color(.systemBackground))
            .cornerRadius(12)
        }
    }
    
    // MARK: - Actions Section
    
    @ViewBuilder
    private var actionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Действия")
                .font(.headline)
                .padding(.horizontal, 4)
            
            VStack(spacing: 0) {
                ActionRow(
                    icon: "envelope.badge.fill",
                    title: "Связь с разработчиками",
                    color: .blue
                ) {
                    showContactDevelopers = true
                }
                
                Divider().padding(.leading, 52)
                
                ActionRow(
                    icon: "arrow.right.square",
                    title: "Выйти",
                    color: .orange
                ) {
                    showLogoutAlert = true
                }
                
                Divider().padding(.leading, 52)
                
                ActionRow(
                    icon: "trash",
                    title: "Удалить аккаунт",
                    color: .red
                ) {
                    showDeleteAccountSheet = true
                }
            }
            .background(Color.cardBackground)
            .cornerRadius(12)
        }
    }
    
    // MARK: - About Section
    
    @ViewBuilder
    private var aboutSection: some View {
        VStack(spacing: 8) {
            Text("InterPrep")
                .font(.headline)
            
            Text("Версия 1.0.0")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.cardBackground)
        .cornerRadius(12)
    }
    
    private var shadowColor: Color {
        colorScheme == .dark ? .clear : .black.opacity(0.05)
    }
}

// MARK: - Stat Card

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(12)
        .shadow(color: shadowColor, radius: 4, x: 0, y: 2)
    }
    
    private var shadowColor: Color {
        colorScheme == .dark ? .clear : .black.opacity(0.05)
    }
}

// MARK: - Settings Row

struct SettingsRow<Content: View>: View {
    let icon: String
    let title: String
    let color: Color
    let content: Content
    
    init(
        icon: String,
        title: String,
        color: Color,
        @ViewBuilder content: () -> Content
    ) {
        self.icon = icon
        self.title = title
        self.color = color
        self.content = content()
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.body)
                .foregroundColor(.white)
                .frame(width: 32, height: 32)
                .background(color)
                .cornerRadius(8)
            
            Text(title)
                .font(.body)
            
            Spacer()
            
            content
        }
        .padding()
    }
}

// MARK: - Interview Row

struct InterviewRow: View {
    let interview: ProfileState.Interview
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // Icon
                Image(systemName: interview.isCompleted ? "checkmark.circle.fill" : "calendar")
                    .font(.body)
                    .foregroundColor(.white)
                    .frame(width: 32, height: 32)
                    .background(interview.isCompleted ? Color.green : Color.brandPrimary)
                    .cornerRadius(8)
                
                // Content
                VStack(alignment: .leading, spacing: 4) {
                    Text(interview.title)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    HStack(spacing: 8) {
                        if !interview.company.isEmpty {
                            Text(interview.company)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                        
                        Text("•")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(interview.date, style: .date)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(interview.date, style: .time)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
        }
    }
}

// MARK: - Action Row

struct ActionRow: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.body)
                    .foregroundColor(.white)
                    .frame(width: 32, height: 32)
                    .background(color)
                    .cornerRadius(8)
                
                Text(title)
                    .font(.body)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
        }
    }
}

// MARK: - Delete Account Sheet

private struct DeleteAccountSheet: View {
    @Binding var password: String
    let errorMessage: String?
    let onConfirm: () -> Void
    let onDismiss: () -> Void
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                Text("Введите пароль для подтверждения. Это действие нельзя отменить, все данные будут удалены.")
                    .font(.body)
                    .foregroundColor(.secondary)
                
                SecureField("Пароль", text: $password)
                    .textFieldStyle(.roundedBorder)
                    .textContentType(.password)
                    .autocapitalization(.none)
                
                if let errorMessage = errorMessage, !errorMessage.isEmpty {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.red)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Удалить аккаунт")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") {
                        onDismiss()
                    }
                }
                ToolbarItem(placement: .destructiveAction) {
                    Button("Удалить") {
                        onConfirm()
                    }
                    .disabled(password.isEmpty)
                }
            }
        }
    }
}

// MARK: - Contact Developers (inline to avoid scope issues)

private struct ProfileContactDevelopersView: View {
    let onDismiss: () -> Void
    private let supportEmail = "InterPrepSupport@mail.ru"
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Связь с разработчиками")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Text("По всем вопросам по работе приложения InterPrep вы можете написать нам на почту. Мы постараемся ответить в ближайшее время.")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Email для обратной связи:")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                        
                        Button {
                            openMail(to: supportEmail)
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "envelope.fill")
                                    .font(.title3)
                                    .foregroundColor(.brandPrimary)
                                Text(supportEmail)
                                    .font(.body)
                                    .fontWeight(.medium)
                                    .foregroundColor(.brandPrimary)
                                Spacer()
                                Image(systemName: "arrow.up.right")
                                    .font(.caption)
                                    .foregroundColor(.brandPrimary)
                            }
                            .padding()
                            .background(Color.brandPrimary.opacity(0.1))
                            .cornerRadius(12)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Разработчики")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Готово") {
                        onDismiss()
                    }
                    .fontWeight(.medium)
                }
            }
        }
    }
    
    private func openMail(to email: String) {
        let subject = "InterPrep — обратная связь"
        let encoded = "mailto:\(email)?subject=\(subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
        guard let url = URL(string: encoded) else { return }
        UIApplication.shared.open(url)
    }
}

// MARK: - Preview

#Preview {
    ProfileView(model: .init(
        user: .init(
            id: "1",
            firstName: "Иван",
            lastName: "Иванов",
            email: "ivan@example.com",
            phone: "+7 999 123-45-67",
            avatarURL: nil,
            position: "iOS Developer",
            experience: "3 года",
            registeredDate: nil
        ),
        cachedProfilePhotoURL: nil,
        statistics: .init(
            totalInterviews: 15,
            completedInterviews: 12,
            upcomingInterviews: 3,
            totalApplications: 45,
            responseRate: 0.75
        ),
        settings: .init(),
        deleteAccountError: nil,
        selectedInterviewTab: .upcoming,
        upcomingInterviews: [
            .init(id: "1", title: "iOS Developer", company: "Яндекс", date: Date().addingTimeInterval(86400), type: "Собеседование", isCompleted: false),
            .init(id: "2", title: "Senior iOS", company: "Сбер", date: Date().addingTimeInterval(172800), type: "Собеседование", isCompleted: false)
        ],
        completedInterviews: [
            .init(id: "3", title: "Middle iOS", company: "Авито", date: Date().addingTimeInterval(-86400), type: "Собеседование", isCompleted: true)
        ],
        isLoadingInterviews: false,
        hasResumeData: true,
        isOfflineMode: false,
        onNotificationsToggled: { _ in },
        onThemeChanged: { _ in },
        onChangeResume: {},
        onViewResume: {},
        onLogout: {},
        onDeleteAccount: { _ in },
        onClearDeleteAccountError: {},
        onInterviewTabChanged: { _ in },
        onInterviewTapped: { _ in },
        onEditProfileTapped: nil,
        editModel: .init(
            firstName: "Иван",
            lastName: "Иванов",
            email: "ivan@example.com",
            cachedProfilePhotoURL: nil,
            avatarURL: nil,
            errorMessage: nil,
            onPhotoSelected: { _ in },
            onFirstNameChanged: { _ in },
            onLastNameChanged: { _ in },
            onSave: {},
            onCancel: {}
        )
    ))
}
