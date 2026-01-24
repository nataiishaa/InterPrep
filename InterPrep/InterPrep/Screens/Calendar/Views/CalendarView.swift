//
//  CalendarView.swift
//  InterPrep
//
//  Calendar screen with swipeable calendar
//

import SwiftUI
import DesignSystem

struct CalendarView: View {
    let model: Model
    @State private var showCalDAVSettings = false
    @State private var isSyncing = false
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 0) {
            header
            calendarGrid
            eventsList
        }
        .background(Color.backgroundPrimary)
        .safeAreaInset(edge: .bottom) {
            Color.clear.frame(height: 60)
        }
        .sheet(isPresented: Binding(
            get: { model.isCreatingEvent },
            set: { if !$0 { model.onCancelEventCreation() } }
        )) {
            EventCreationView(model: model.eventCreationModel)
        }
        .sheet(isPresented: $showCalDAVSettings) {
            CalDAVSettingsView(
                settings: CalDAVSettingsManager.shared.loadSettings(),
                onSave: { settings in
                    CalDAVSettingsManager.shared.saveSettings(settings)
                    if settings.isEnabled {
                        performSync()
                    }
                }
            )
        }
    }
    
    // MARK: - Header
    
    @ViewBuilder
    private var header: some View {
        VStack(spacing: 16) {
            // Month navigation with sync button
            HStack {
                Button {
                    model.onMonthChanged(previousMonth)
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.title3)
                        .foregroundColor(.brandPrimary)
                        .frame(width: 44, height: 44)
                }
                
                Spacer()
                
                Text(monthYearString)
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                // CalDAV sync button
                Menu {
                    Button {
                        performSync()
                    } label: {
                        Label("Синхронизировать", systemImage: "arrow.triangle.2.circlepath")
                    }
                    .disabled(isSyncing)
                    
                    Button {
                        showCalDAVSettings = true
                    } label: {
                        Label("Настройки CalDAV", systemImage: "gearshape")
                    }
                } label: {
                    if isSyncing {
                        ProgressView()
                            .scaleEffect(0.8)
                            .frame(width: 44, height: 44)
                    } else {
                        Image(systemName: "ellipsis.circle")
                            .font(.title3)
                            .foregroundColor(.brandPrimary)
                            .frame(width: 44, height: 44)
                    }
                }
                
                Button {
                    model.onMonthChanged(nextMonth)
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.title3)
                        .foregroundColor(.brandPrimary)
                        .frame(width: 44, height: 44)
                }
            }
            .padding(.horizontal)
            
            // Weekday headers
            HStack(spacing: 0) {
                ForEach(weekdaySymbols, id: \.self) { symbol in
                    Text(symbol)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal)
        }
        .padding(.top, 16)
        .padding(.bottom, 8)
        .background(Color(.systemBackground))
    }
    
    // MARK: - Calendar Grid
    
    @ViewBuilder
    private var calendarGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
            ForEach(daysInMonth, id: \.self) { date in
                if let date = date {
                    CalendarDayCell(
                        date: date,
                        isSelected: date.isSameDay(as: model.selectedDate),
                        isToday: date.isSameDay(as: Date()),
                        hasEvents: model.events.contains(where: { $0.date.isSameDay(as: date) }),
                        isCurrentMonth: date.isSameMonth(as: model.currentMonth),
                        onTap: { model.onDateSelected(date) }
                    )
                } else {
                    Color.clear
                        .frame(height: 50)
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
    }
    
    // MARK: - Events List
    
    @ViewBuilder
    private var eventsList: some View {
        VStack(spacing: 0) {
            HStack {
                Text(selectedDateString)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button {
                    model.onCreateEventTapped()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus.circle.fill")
                        Text("Добавить")
                    }
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.brandPrimary)
                }
            }
            .padding()
            .background(Color(.systemBackground))
            
            if eventsForSelectedDate.isEmpty {
                emptyEventsView
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(eventsForSelectedDate) { event in
                            EventCard(event: event, model: model)
                        }
                    }
                    .padding()
                }
            }
        }
    }
    
    @ViewBuilder
    private var emptyEventsView: some View {
        VStack(spacing: 16) {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 50))
                .foregroundColor(.secondary.opacity(0.5))
            
            Text("Нет событий")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("Нажмите + чтобы добавить событие")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    // MARK: - Helpers
    
    private var weekdaySymbols: [String] {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        return formatter.shortWeekdaySymbols.map { String($0.prefix(2)) }
    }
    
    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.dateFormat = "LLLL yyyy"
        return formatter.string(from: model.currentMonth).capitalized
    }
    
    private var selectedDateString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.dateFormat = "d MMMM, EEEE"
        return formatter.string(from: model.selectedDate).capitalized
    }
    
    private var previousMonth: Date {
        Calendar.current.date(byAdding: .month, value: -1, to: model.currentMonth) ?? model.currentMonth
    }
    
    private var nextMonth: Date {
        Calendar.current.date(byAdding: .month, value: 1, to: model.currentMonth) ?? model.currentMonth
    }
    
    private var daysInMonth: [Date?] {
        let calendar = Calendar.current
        let startOfMonth = model.currentMonth.startOfMonth
        let range = calendar.range(of: .day, in: .month, for: startOfMonth)!
        
        let firstWeekday = calendar.component(.weekday, from: startOfMonth)
        let numberOfEmptyDays = (firstWeekday + 5) % 7 // Adjust for Monday start
        
        var days: [Date?] = Array(repeating: nil, count: numberOfEmptyDays)
        
        for day in range {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: startOfMonth) {
                days.append(date)
            }
        }
        
        return days
    }
    
    private var eventsForSelectedDate: [CalendarState.CalendarEvent] {
        model.events.filter { $0.date.isSameDay(as: model.selectedDate) }
            .sorted { $0.date < $1.date }
    }
    
    private func performSync() {
        let settings = CalDAVSettingsManager.shared.loadSettings()
        guard settings.isEnabled else {
            showCalDAVSettings = true
            return
        }
        
        isSyncing = true
        
        Task {
            do {
                let syncManager = CalDAVSyncManager()
                try await syncManager.setup()
                let syncedEvents = try await syncManager.performFullSync(localEvents: model.events)
                
                // Notify about sync completion
                await MainActor.run {
                    model.onSyncCompleted(syncedEvents)
                    isSyncing = false
                }
            } catch {
                await MainActor.run {
                    // Show error
                    isSyncing = false
                }
            }
        }
    }
}

// MARK: - Calendar Day Cell

struct CalendarDayCell: View {
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    let hasEvents: Bool
    let isCurrentMonth: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                Text("\(Calendar.current.component(.day, from: date))")
                    .font(.system(size: 16, weight: isSelected ? .bold : .regular))
                    .foregroundColor(textColor)
                
                if hasEvents {
                    Circle()
                        .fill(dotColor)
                        .frame(width: 4, height: 4)
                } else {
                    Color.clear.frame(height: 4)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(backgroundColor)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(borderColor, lineWidth: isToday ? 2 : 0)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var textColor: Color {
        if !isCurrentMonth {
            return .secondary.opacity(0.3)
        }
        if isSelected {
            return .white
        }
        return .primary
    }
    
    private var backgroundColor: Color {
        if isSelected {
            return .brandPrimary
        }
        return Color.clear
    }
    
    private var borderColor: Color {
        isToday ? .brandPrimary : .clear
    }
    
    private var dotColor: Color {
        isSelected ? .white : .brandPrimary
    }
}

// MARK: - Event Card

struct EventCard: View {
    let event: CalendarState.CalendarEvent
    let model: CalendarView.Model
    
    var body: some View {
        HStack(spacing: 12) {
            // Type indicator
            VStack {
                Image(systemName: event.type.icon)
                    .font(.title3)
                    .foregroundColor(typeColor)
                    .frame(width: 40, height: 40)
                    .background(typeColor.opacity(0.15))
                    .cornerRadius(8)
                
                Spacer()
            }
            
            // Event info
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
            
            Spacer()
            
            // Actions
            Menu {
                Button {
                    model.onToggleEventCompletion(event.id)
                } label: {
                    Label(
                        event.isCompleted ? "Отметить как незавершенное" : "Отметить как завершенное",
                        systemImage: event.isCompleted ? "circle" : "checkmark.circle"
                    )
                }
                
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
        formatter.timeStyle = .short
        return formatter.string(from: event.date)
    }
}

// MARK: - Model

extension CalendarView {
    struct Model {
        let selectedDate: Date
        let currentMonth: Date
        let events: [CalendarState.CalendarEvent]
        let isCreatingEvent: Bool
        let onDateSelected: (Date) -> Void
        let onMonthChanged: (Date) -> Void
        let onCreateEventTapped: () -> Void
        let onCancelEventCreation: () -> Void
        let onDeleteEvent: (String) -> Void
        let onToggleEventCompletion: (String) -> Void
        let onSyncCompleted: ([CalendarState.CalendarEvent]) -> Void
        let eventCreationModel: EventCreationView.Model
    }
}

// MARK: - Preview

#Preview {
    CalendarView(model: .init(
        selectedDate: Date(),
        currentMonth: Date(),
        events: [
            .init(
                title: "Собеседование в Яндекс",
                description: "Техническое интервью",
                date: Date(),
                type: .interview
            ),
            .init(
                title: "Тестовое задание",
                description: "Завершить до конца дня",
                date: Date().addingTimeInterval(3600),
                type: .test
            )
        ],
        isCreatingEvent: false,
        onDateSelected: { _ in },
        onMonthChanged: { _ in },
        onCreateEventTapped: {},
        onCancelEventCreation: {},
        onDeleteEvent: { _ in },
        onToggleEventCompletion: { _ in },
        onSyncCompleted: { _ in },
        eventCreationModel: .init(
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
        )
    ))
}
