//
//  EventCreationView.swift
//  InterPrep
//
//  Event creation form
//

import DesignSystem
import SwiftUI

struct EventCreationView: View {
    let model: Model
    @Environment(\.dismiss) private var dismiss
    
    private static let reminderOptions: [(Int, String)] = [
        (5, "5 минут"),
        (15, "15 минут"),
        (30, "30 минут"),
        (60, "1 час"),
        (120, "2 часа"),
        (1440, "1 день")
    ]
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Название", text: Binding(
                        get: { model.title },
                        set: { model.onTitleChanged($0) }
                    ), prompt: Text("Название"))
                    
                    TextField("Адрес или ссылка на встречу", text: Binding(
                        get: { model.description },
                        set: { model.onDescriptionChanged($0) }
                    ), axis: .vertical)
                    .lineLimit(3...6)
                }
                
                Section {
                    Picker(selection: Binding(
                        get: { model.type },
                        set: { model.onTypeChanged($0) }
                    )) {
                        ForEach(CalendarState.EventType.allCases, id: \.self) { type in
                            Label(type.rawValue, systemImage: type.icon)
                                .tag(type)
                        }
                    } label: {
                        Text("Тип события")
                    }
                    
                    DatePicker("Начало", selection: Binding(
                        get: { model.startDateTime },
                        set: { model.onStartDateTimeChanged($0) }
                    ), displayedComponents: [.date, .hourAndMinute])
                    .environment(\.locale, Locale(identifier: "ru_RU"))
                    
                    DatePicker("Конец", selection: Binding(
                        get: { model.endDate },
                        set: { model.onEndDateChanged($0) }
                    ), displayedComponents: [.date, .hourAndMinute])
                    .environment(\.locale, Locale(identifier: "ru_RU"))
                }
                
                Section {
                    Toggle("Напоминание", isOn: Binding(
                        get: { model.reminderEnabled },
                        set: { model.onReminderToggled($0) }
                    ))
                    .tint(.brandPrimary)
                    
                    if model.reminderEnabled {
                        Picker(selection: Binding(
                            get: { model.reminderMinutes },
                            set: { model.onReminderMinutesChanged($0) }
                        )) {
                            ForEach(Self.reminderOptions, id: \.0) { value, title in
                                Text(title).tag(value)
                            }
                        } label: {
                            Text("За сколько напомнить")
                        }
                    }
                }
                
                if let error = model.errorMessage {
                    Section {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                            Text(error)
                                .font(.subheadline)
                                .foregroundColor(.red)
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color(.systemGroupedBackground))
            .navigationTitle(model.isEditing ? "Редактировать" : "Событие")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отменить") {
                        model.onCancel()
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(model.isEditing ? "Сохранить" : "Добавить") {
                        model.onSave()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(model.title.isEmpty)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    EventCreationView(model: .init(
        isEditing: false,
        title: "",
        description: "",
        startDateTime: Date(),
        endDate: Date().addingTimeInterval(3600),
        type: .interview,
        reminderEnabled: true,
        reminderMinutes: 30,
        errorMessage: nil,
        onTitleChanged: { _ in },
        onDescriptionChanged: { _ in },
        onStartDateTimeChanged: { _ in },
        onEndDateChanged: { _ in },
        onTypeChanged: { _ in },
        onReminderToggled: { _ in },
        onReminderMinutesChanged: { _ in },
        onSave: {},
        onCancel: {}
    ))
}
