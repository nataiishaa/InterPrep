import DesignSystem
import SwiftUI

public struct CalDAVSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var settings: CalDAVSettings
    @State private var selectedPreset: CalDAVPreset?
    @State private var isTestingConnection = false
    @State private var connectionStatus: ConnectionStatus?
    @State private var showPassword = false

    private let onSave: (CalDAVSettings) -> Void

    enum ConnectionStatus {
        case success
        case failure(String)
    }

    public init(settings: CalDAVSettings, onSave: @escaping (CalDAVSettings) -> Void) {
        _settings = State(initialValue: settings)
        self.onSave = onSave
    }

    public var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Зачем это нужно?")
                            .font(.headline)
                            .foregroundColor(.primary)

                        Text("Собеседования из InterPrep появятся в вашем обычном календаре: Apple Calendar, iCloud, Fastmail или Nextcloud. Если вы измените время или удалите событие в приложении, календарь тоже обновится.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        Text("Так вы не пропустите встречу и будете видеть расписание там, где уже привыкли смотреть дела.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }

                Section {
                    Toggle("Включить синхронизацию", isOn: $settings.isEnabled)
                        .tint(.brandPrimary)
                } header: {
                    Text("Синхронизация с календарём")
                } footer: {
                    Text("Можно оставить выключенным: тогда события будут храниться только внутри InterPrep.")
                }

                if settings.isEnabled {
                    Section("Сервис календаря") {
                        ForEach(CalDAVSettings.presets, id: \.name) { preset in
                            Button {
                                selectedPreset = preset
                                if !preset.serverURL.isEmpty {
                                    settings.serverURL = preset.serverURL
                                }
                            } label: {
                                HStack {
                                    Text(preset.name)
                                        .foregroundColor(.primary)
                                    Spacer()
                                    if selectedPreset?.name == preset.name {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.brandPrimary)
                                    }
                                }
                            }
                        }
                    }

                    if let preset = selectedPreset {
                        Section {
                            Text(preset.instructions)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    Section {
                        TextField("Адрес сервера календаря", text: $settings.serverURL)
                            .textContentType(.URL)
                            .keyboardType(.URL)
                            .autocapitalization(.none)

                        TextField("Имя пользователя (email)", text: $settings.username)
                            .textContentType(.username)
                            .autocapitalization(.none)
                            .keyboardType(.emailAddress)

                        HStack {
                            if showPassword {
                                TextField("Пароль приложения", text: $settings.password)
                                    .textContentType(.password)
                            } else {
                                SecureField("Пароль приложения", text: $settings.password)
                                    .textContentType(.password)
                            }

                            Button {
                                showPassword.toggle()
                            } label: {
                                Image(systemName: showPassword ? "eye.slash" : "eye")
                                    .foregroundColor(.secondary)
                            }
                        }
                    } header: {
                        Text("Данные для входа")
                    } footer: {
                        Text("Используйте пароль приложения, не основной пароль от аккаунта. Для iCloud: appleid.apple.com → Пароли для приложений")
                            .font(.caption)
                    }

                    Section {
                        Button {
                            testConnection()
                        } label: {
                            HStack {
                                if isTestingConnection {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                } else {
                                    Image(systemName: "network")
                                }
                                Text("Проверить подключение")
                            }
                        }
                        .disabled(isTestingConnection || !isFormValid)

                        if let status = connectionStatus {
                            switch status {
                            case .success:
                                Label("Подключение успешно", systemImage: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                            case .failure(let error):
                                Label(error, systemImage: "xmark.circle.fill")
                                    .foregroundColor(.red)
                            }
                        }
                    }

                    if let lastSync = settings.lastSyncDate {
                        Section("Информация") {
                            HStack {
                                Text("Последняя синхронизация")
                                Spacer()
                                Text(lastSync, style: .relative)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("CalDAV")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Сохранить") {
                        onSave(settings)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(!isFormValid && settings.isEnabled)
                }
            }
        }
    }

    private var isFormValid: Bool {
        !settings.serverURL.isEmpty &&
        !settings.username.isEmpty &&
        !settings.password.isEmpty
    }

    func testConnection() {
        isTestingConnection = true
        connectionStatus = nil

        Task {
            do {
                var settingsToSave = settings
                settingsToSave.selectedCalendarURL = nil
                CalDAVSettingsManager.shared.saveSettings(settingsToSave)

                let manager = CalDAVSyncManager()
                try await manager.setup()

                let updatedSettings = CalDAVSettingsManager.shared.loadSettings()

                await MainActor.run {
                    settings = updatedSettings
                    connectionStatus = .success
                    isTestingConnection = false
                }
            } catch let caldavError as CalDAVError {
                await MainActor.run {
                    connectionStatus = .failure(caldavError.errorDescription ?? "Не удалось подключиться")
                    isTestingConnection = false
                }
            } catch {
                await MainActor.run {
                    connectionStatus = .failure(error.localizedDescription)
                    isTestingConnection = false
                }
            }
        }
    }
}

#Preview {
    CalDAVSettingsView(
        settings: CalDAVSettings(),
        onSave: { _ in }
    )
}
