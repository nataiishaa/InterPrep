//
//  EventCard.swift
//  InterPrep
//
//  Compact event row in the calendar day list
//

import DesignSystem
import NetworkMonitorService
import SwiftUI

struct EventCard: View {
    let event: CalendarState.CalendarEvent
    let model: CalendarView.Model
    var onTap: (() -> Void)?
    
    var body: some View {
        HStack(spacing: 12) {
            VStack {
                Image(systemName: event.type.icon)
                    .font(.title3)
                    .foregroundColor(typeColor)
                    .frame(width: 40, height: 40)
                    .background(typeColor.opacity(0.15))
                    .cornerRadius(8)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(event.title)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .strikethrough(event.isCompleted)
                
                if !event.description.isEmpty {
                    Text(event.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                HStack(spacing: 8) {
                    Label(timeString, systemImage: "clock")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if event.reminderEnabled {
                        Label("\(event.reminderMinutesBefore) мин", systemImage: "bell.fill")
                            .font(.caption)
                            .foregroundColor(.brandPrimary)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .onTapGesture {
                onTap?()
            }
            
            Menu {
                Button(role: .destructive) {
                    model.onDeleteEvent(event.id)
                } label: {
                    Label("Удалить", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .frame(width: 44, height: 44)
            }
            .disabled(!NetworkMonitor.shared.isConnected)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
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
    
    private var timeString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.timeStyle = .short
        return formatter.string(from: event.date)
    }
}
