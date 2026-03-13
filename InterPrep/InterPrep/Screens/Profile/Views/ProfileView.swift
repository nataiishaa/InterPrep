//
//  ProfileView.swift
//  InterPrep
//
//  Profile screen with settings and statistics
//

import SwiftUI
import DesignSystem
import CalendarFeature

struct ProfileView: View {
    let model: Model
    @State private var showEditProfile = false
    @State private var showCalDAVSettings = false
    @State private var showContactDevelopers = false
    @State private var showLogoutAlert = false
    @State private var showDeleteAccountAlert = false
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                profileHeader
                resumeSection
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
        }
        .alert("Удалить аккаунт?", isPresented: $showDeleteAccountAlert) {
            Button("Отмена", role: .cancel) {}
            Button("Удалить", role: .destructive) {
                model.onDeleteAccount()
            }
        } message: {
            Text("Это действие нельзя отменить. Все ваши данные будут удалены.")
        }
    }
    
    // MARK: - Profile Header
    
    @ViewBuilder
    private var profileHeader: some View {
        VStack(spacing: 16) {
            // Avatar
            ZStack(alignment: .bottomTrailing) {
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
                        Text(model.user?.initials ?? "??")
                            .font(.system(size: 40, weight: .bold))
                            .foregroundColor(.white)
                    )
                
                Button {
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
            
            // Name and info
            VStack(spacing: 4) {
                Text(model.user?.fullName ?? "Пользователь")
                    .font(.title2)
                    .fontWeight(.bold)
                
                if let position = model.user?.position {
                    Text(position)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                if let email = model.user?.email {
                    Text(email)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Member since
            if let registeredDate = model.user?.registeredDate {
                Text("С нами с \(registeredDate, style: .date)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.cardBackground)
        .cornerRadius(16)
        .shadow(color: shadowColor, radius: 8, x: 0, y: 2)
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
                    // Icon
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
                        Text("Ваше резюме загружено")
                            .font(.body)
                            .fontWeight(.medium)
                        
                        Text("Если что-то поменялось, можно загрузить новое резюме")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                    
                    Spacer()
                }
                .padding()
                
                Divider()
                
                Button {
                    model.onChangeResume()
                } label: {
                    HStack {
                        Image(systemName: "arrow.up.doc.fill")
                            .font(.body)
                        Text("Загрузить новое резюме")
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
    
    // MARK: - Settings Section
    
    @ViewBuilder
    private var settingsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Настройки")
                .font(.headline)
                .padding(.horizontal, 4)
            
            VStack(spacing: 0) {
                SettingsRow(
                    icon: "bell.fill",
                    title: "Уведомления",
                    color: .red
                ) {
                    Toggle("", isOn: Binding(
                        get: { model.settings.notificationsEnabled },
                        set: { model.onNotificationsToggled($0) }
                    ))
                    .tint(.brandPrimary)
                }
                
                Divider().padding(.leading, 52)
                
                SettingsRow(
                    icon: "envelope.fill",
                    title: "Email уведомления",
                    color: .blue
                ) {
                    Toggle("", isOn: Binding(
                        get: { model.settings.emailNotifications },
                        set: { model.onEmailNotificationsToggled($0) }
                    ))
                    .tint(.brandPrimary)
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
                
                Text("Подключите Google, iCloud или другой календарь — собеседования появятся в приложении.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
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
                    showDeleteAccountAlert = true
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
            
            // Dev tools
            VStack(spacing: 12) {
                Divider()
                    .padding(.horizontal)
                
                Text("Для разработки:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Button("Сбросить онбординг") {
                    resetApp()
                }
                .buttonStyle(.bordered)
                .tint(.brandPrimary)
            }
            .padding(.top, 8)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.cardBackground)
        .cornerRadius(12)
    }
    
    private func resetApp() {
        // Reset onboarding flag
        UserDefaults.standard.set(false, forKey: "isOnboardingCompleted")
        
        // Note: To see the onboarding screen, restart the app manually
        // App-level navigation should be handled by the app coordinator, not by feature modules
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

// MARK: - Model

extension ProfileView {
    struct Model {
        let user: ProfileState.User?
        let statistics: ProfileState.Statistics
        let settings: ProfileState.AppSettings
        let onNotificationsToggled: (Bool) -> Void
        let onEmailNotificationsToggled: (Bool) -> Void
        let onThemeChanged: (ProfileState.AppSettings.Theme) -> Void
        let onChangeResume: () -> Void
        let onLogout: () -> Void
        let onDeleteAccount: () -> Void
        let editModel: ProfileEditView.Model
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
            registeredDate: Date()
        ),
        statistics: .init(
            totalInterviews: 15,
            completedInterviews: 12,
            upcomingInterviews: 3,
            totalApplications: 45,
            responseRate: 0.75
        ),
        settings: .init(),
        onNotificationsToggled: { _ in },
        onEmailNotificationsToggled: { _ in },
        onThemeChanged: { _ in },
        onChangeResume: {},
        onLogout: {},
        onDeleteAccount: {},
        editModel: .init(
            firstName: "Иван",
            lastName: "Иванов",
            errorMessage: nil,
            onFirstNameChanged: { _ in },
            onLastNameChanged: { _ in },
            onSave: {},
            onCancel: {}
        )
    ))
}
