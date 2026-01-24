//
//  EventCreationView.swift
//  InterPrep
//
//  Event creation form
//

import SwiftUI
import DesignSystem

struct EventCreationView: View {
    let model: Model
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Title
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Название")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                        
                        TextField("Например: Собеседование в Яндекс", text: Binding(
                            get: { model.title },
                            set: { model.onTitleChanged($0) }
                        ))
                        .textFieldStyle(.roundedBorder)
                    }
                    
                    // Description
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Описание")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                        
                        TextEditor(text: Binding(
                            get: { model.description },
                            set: { model.onDescriptionChanged($0) }
                        ))
                        .frame(height: 100)
                        .padding(8)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    }
                    
                    // Type
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Тип события")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(CalendarState.EventType.allCases, id: \.self) { type in
                                    EventTypeButton(
                                        type: type,
                                        isSelected: model.type == type,
                                        action: { model.onTypeChanged(type) }
                                    )
                                }
                            }
                        }
                    }
                    
                    // Date and Time
                    VStack(spacing: 16) {
                        HStack(spacing: 16) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Дата")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.secondary)
                                
                                DatePicker("", selection: Binding(
                                    get: { model.date },
                                    set: { model.onDateChanged($0) }
                                ), displayedComponents: .date)
                                .datePickerStyle(.compact)
                                .labelsHidden()
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Время")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.secondary)
                                
                                DatePicker("", selection: Binding(
                                    get: { model.time },
                                    set: { model.onTimeChanged($0) }
                                ), displayedComponents: .hourAndMinute)
                                .datePickerStyle(.compact)
                                .labelsHidden()
                            }
                        }
                    }
                    
                    // Reminder
                    VStack(alignment: .leading, spacing: 12) {
                        Toggle("Напоминание", isOn: Binding(
                            get: { model.reminderEnabled },
                            set: { model.onReminderToggled($0) }
                        ))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .tint(.brandPrimary)
                        
                        if model.reminderEnabled {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("За сколько минут напомнить")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Picker("", selection: Binding(
                                    get: { model.reminderMinutes },
                                    set: { model.onReminderMinutesChanged($0) }
                                )) {
                                    Text("5 минут").tag(5)
                                    Text("15 минут").tag(15)
                                    Text("30 минут").tag(30)
                                    Text("1 час").tag(60)
                                    Text("2 часа").tag(120)
                                    Text("1 день").tag(1440)
                                }
                                .pickerStyle(.segmented)
                            }
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // Error message
                    if let error = model.errorMessage {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                            Text(error)
                                .font(.subheadline)
                                .foregroundColor(.red)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Новое событие")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") {
                        model.onCancel()
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Сохранить") {
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

// MARK: - Event Type Button

struct EventTypeButton: View {
    let type: CalendarState.EventType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: type.icon)
                    .font(.title3)
                    .foregroundColor(isSelected ? .white : typeColor)
                
                Text(type.rawValue)
                    .font(.caption2)
                    .foregroundColor(isSelected ? .white : .primary)
            }
            .frame(width: 80, height: 80)
            .background(isSelected ? typeColor : Color(.systemGray6))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var typeColor: Color {
        switch type {
        case .interview: return .brandPrimary
        case .test: return .blue
        case .call: return .green
        case .meeting: return .orange
        case .deadline: return .red
        case .other: return .purple
        }
    }
}

// MARK: - Model

extension EventCreationView {
    struct Model {
        let title: String
        let description: String
        let date: Date
        let time: Date
        let type: CalendarState.EventType
        let reminderEnabled: Bool
        let reminderMinutes: Int
        let errorMessage: String?
        let onTitleChanged: (String) -> Void
        let onDescriptionChanged: (String) -> Void
        let onDateChanged: (Date) -> Void
        let onTimeChanged: (Date) -> Void
        let onTypeChanged: (CalendarState.EventType) -> Void
        let onReminderToggled: (Bool) -> Void
        let onReminderMinutesChanged: (Int) -> Void
        let onSave: () -> Void
        let onCancel: () -> Void
    }
}

// MARK: - Preview

#Preview {
    EventCreationView(model: .init(
        title: "",
        description: "",
        date: Date(),
        time: Date(),
        type: .interview,
        reminderEnabled: true,
        reminderMinutes: 30,
        errorMessage: nil,
        onTitleChanged: { _ in },
        onDescriptionChanged: { _ in },
        onDateChanged: { _ in },
        onTimeChanged: { _ in },
        onTypeChanged: { _ in },
        onReminderToggled: { _ in },
        onReminderMinutesChanged: { _ in },
        onSave: {},
        onCancel: {}
    ))
}
