//
//  EventDetailSheet.swift
//  InterPrep
//
//  Full-screen sheet with event details and actions
//

import DesignSystem
import NetworkMonitorService
import SwiftUI

struct EventDetailSheet: View {
    let event: CalendarState.CalendarEvent
    let model: CalendarView.Model
    let onDismiss: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    private static var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.dateFormat = "EEEE, d MMMM yyyy 'г.'"
        return formatter
    }
    
    private static var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.timeStyle = .short
        return formatter
    }
    
    private var dateTimeText: String {
        let startDate = event.date
        let endDate = event.endDate ?? event.date.addingTimeInterval(3600)
        let startDateStr = Self.dateFormatter.string(from: startDate)
        let startTimeStr = Self.timeFormatter.string(from: startDate)
        let endTimeStr = Self.timeFormatter.string(from: endDate)
        let isSameDay = Calendar.current.isDate(startDate, inSameDayAs: endDate)
        if isSameDay {
            return "\(startDateStr) с \(startTimeStr) до \(endTimeStr)"
        } else {
            let endDateStr = Self.dateFormatter.string(from: endDate)
            return "\(startDateStr) с \(startTimeStr) до \(endDateStr) \(endTimeStr)"
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(alignment: .top) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(typeColor.opacity(0.85))
                                .frame(width: 4)
                            VStack(alignment: .leading, spacing: 6) {
                                Text(event.title)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.primary)
                                    .strikethrough(event.isCompleted)
                                HStack(spacing: 6) {
                                    Image(systemName: "calendar")
                                        .font(.subheadline)
                                        .foregroundColor(typeColor)
                                    Text(dateTimeText)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            }
                            Spacer(minLength: 0)
                        }
                        .padding(16)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(12)
                    
                    if !event.description.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 8) {
                                Image(systemName: "note.text")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Text("Описание")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.secondary)
                            }
                            Text(event.description)
                                .font(.body)
                                .foregroundColor(.primary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(16)
                        .background(Color(.secondarySystemGroupedBackground))
                        .cornerRadius(12)
                    }
                    
                    VStack(spacing: 0) {
                        HStack(spacing: 12) {
                            Image(systemName: event.type.icon)
                                .font(.body)
                                .foregroundColor(typeColor)
                                .frame(width: 24, alignment: .center)
                            Text(event.type.rawValue)
                                .font(.subheadline)
                                .foregroundColor(.primary)
                            Spacer()
                            if event.isCompleted {
                                Text("Завершено")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(Color.green)
                                    .cornerRadius(8)
                            }
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal, 16)
                        
                        if event.reminderEnabled {
                            Divider()
                                .padding(.leading, 52)
                            HStack(spacing: 12) {
                                Image(systemName: "bell.fill")
                                    .font(.subheadline)
                                    .foregroundColor(.brandPrimary)
                                    .frame(width: 24, alignment: .center)
                                Text("Напоминание за \(event.reminderMinutesBefore) мин")
                                    .font(.subheadline)
                                    .foregroundColor(.primary)
                                Spacer()
                            }
                            .padding(.vertical, 12)
                            .padding(.horizontal, 16)
                        }
                        
                        Divider()
                            .padding(.leading, 52)
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: "sparkles")
                                .font(.subheadline)
                                .foregroundColor(.brandPrimary)
                                .frame(width: 24, alignment: .center)
                            Text("Удачи на этапе «\(event.type.rawValue)»!")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.brandPrimary)
                            Spacer()
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal, 16)
                    }
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(12)
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 32)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Подробнее")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Закрыть") {
                        onDismiss()
                        dismiss()
                    }
                    .foregroundColor(.brandPrimary)
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Редактировать") {
                        model.onEditEvent(event)
                        onDismiss()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(!NetworkMonitor.shared.isConnected)
                }
            }
        }
    }
    
    private var typeColor: Color {
        switch event.type {
        case .interview: return .brandPrimary
        case .test: return .blue
        case .call: return .green
        case .meeting: return .orange
        case .deadline: return .red
        case .other: return .purple
        }
    }
}
