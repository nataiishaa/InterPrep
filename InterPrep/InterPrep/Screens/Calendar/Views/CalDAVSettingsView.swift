//
//  CalDAVSettingsView.swift
//  InterPrep
//
//  CalDAV connection settings UI
//

import SwiftUI
import DesignSystem

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
                    Toggle("Включить синхронизацию", isOn: $settings.isEnabled)
                        .tint(.brandPrimary)
                } header: {
                    Text("Что это?")
                } footer: {
                    Text("Подключите ваш календарь (Google, iCloud и др.) — события и собеседования из календаря будут отображаться в приложении. Укажите сервер календаря и данные для входа.")
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
                    
                    Section("Данные для входа") {
                        TextField("Адрес сервера календаря", text: $settings.serverURL)
                            .textContentType(.URL)
                            .keyboardType(.URL)
                            .autocapitalization(.none)
                        
                        TextField("Имя пользователя", text: $settings.username)
                            .textContentType(.username)
                            .autocapitalization(.none)
                        
                        HStack {
                            if showPassword {
                                TextField("Пароль", text: $settings.password)
                                    .textContentType(.password)
                            } else {
                                SecureField("Пароль", text: $settings.password)
                                    .textContentType(.password)
                            }
                            
                            Button {
                                showPassword.toggle()
                            } label: {
                                Image(systemName: showPassword ? "eye.slash" : "eye")
                                    .foregroundColor(.secondary)
                            }
                        }
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
            .navigationTitle("Календарь")
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
    
    private func testConnection() {
        isTestingConnection = true
        connectionStatus = nil
        
        Task {
            do {
                let manager = CalDAVSyncManager()
                CalDAVSettingsManager.shared.saveSettings(settings)
                try await manager.setup()
                let success = try await manager.testConnection()
                
                await MainActor.run {
                    connectionStatus = success ? .success : .failure("Не удалось подключиться")
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
