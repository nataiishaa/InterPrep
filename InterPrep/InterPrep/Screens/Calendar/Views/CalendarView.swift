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
    @State private var lastCalDAVOpenTime: Date = .distantPast
    @State private var showMonthYearPicker = false
    @State private var selectedEventForDetail: CalendarState.CalendarEvent?
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
        .sheet(isPresented: $showMonthYearPicker) {
            MonthYearPickerView(
                currentMonth: model.currentMonth,
                onSelect: { date in
                    model.onMonthChanged(date)
                    showMonthYearPicker = false
                },
                onDismiss: { showMonthYearPicker = false }
            )
        }
        .sheet(item: $selectedEventForDetail) { event in
            EventDetailSheet(
                event: event,
                model: model,
                onDismiss: { selectedEventForDetail = nil }
            )
        }
        .sheet(isPresented: $showCalDAVSettings, onDismiss: {
            // Reset so next open works; avoids double presentation when Menu fires twice
            lastCalDAVOpenTime = .distantPast
        }) {
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
                
                Button {
                    showMonthYearPicker = true
                } label: {
                    HStack(spacing: 4) {
                        Text(monthYearString)
                            .font(.title2)
                            .fontWeight(.bold)
                        Image(systemName: "chevron.down.circle.fill")
                            .font(.caption)
                            .foregroundColor(.brandPrimary.opacity(0.8))
                    }
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                // Синхронизация с календарём (CalDAV) — один пункт, открывает настройки
                Button {
                    openCalDAVSettingsOnce()
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.title3)
                        .foregroundColor(.brandPrimary)
                        .frame(width: 44, height: 44)
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
            ForEach(Array(daysInMonth.enumerated()), id: \.offset) { index, date in
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
                        .id("empty-\(index)")
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
                            EventCard(event: event, model: model, onTap: {
                                selectedEventForDetail = event
                            })
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
    
    private func openCalDAVSettingsOnce() {
        let now = Date()
        guard now.timeIntervalSince(lastCalDAVOpenTime) > 0.5 else { return }
        lastCalDAVOpenTime = now
        showCalDAVSettings = true
    }
    
    private func performSync() {
        let settings = CalDAVSettingsManager.shared.loadSettings()
        guard settings.isEnabled else {
            openCalDAVSettingsOnce()
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

// MARK: - Month Year Picker

private struct MonthYearPickerView: View {
    let currentMonth: Date
    let onSelect: (Date) -> Void
    let onDismiss: () -> Void
    
    @State private var selectedYear: Int
    private let calendar = Calendar.current
    private let monthSymbols: [String]
    
    init(currentMonth: Date, onSelect: @escaping (Date) -> Void, onDismiss: @escaping () -> Void) {
        self.currentMonth = currentMonth
        self.onSelect = onSelect
        self.onDismiss = onDismiss
        _selectedYear = State(initialValue: Calendar.current.component(.year, from: currentMonth))
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.dateFormat = "LLL"
        var symbols: [String] = []
        for i in 1...12 {
            var comp = DateComponents()
            comp.month = i
            comp.day = 1
            if let date = Calendar.current.date(from: comp) {
                symbols.append(formatter.string(from: date).capitalized)
            }
        }
        self.monthSymbols = symbols
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Year
                HStack {
                    Text("Год")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    Spacer()
                    HStack(spacing: 16) {
                        Button {
                            selectedYear = max(selectedYear - 1, 1970)
                        } label: {
                            Image(systemName: "chevron.left.circle.fill")
                                .font(.title2)
                                .foregroundColor(.brandPrimary)
                        }
                        Text(verbatim: String(selectedYear))
                            .font(.title2)
                            .fontWeight(.semibold)
                            .frame(minWidth: 60)
                        Button {
                            selectedYear = min(selectedYear + 1, 2100)
                        } label: {
                            Image(systemName: "chevron.right.circle.fill")
                                .font(.title2)
                                .foregroundColor(.brandPrimary)
                        }
                    }
                }
                .padding(.horizontal)
                
                // Months grid
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
                    ForEach(Array(monthSymbols.enumerated()), id: \.offset) { index, name in
                        let month = index + 1
                        let isSelected = isCurrentSelectedMonth(month: month)
                        Button {
                            if let date = dateFor(month: month, year: selectedYear) {
                                onSelect(date)
                            }
                        } label: {
                            Text(name)
                                .font(.subheadline)
                                .fontWeight(isSelected ? .semibold : .regular)
                                .foregroundColor(isSelected ? .white : .primary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(isSelected ? Color.brandPrimary : Color(.systemGray6))
                                .cornerRadius(10)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
                
                Spacer(minLength: 0)
            }
            .padding(.top, 20)
            .navigationTitle("Месяц и год")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Закрыть") {
                        onDismiss()
                    }
                    .foregroundColor(.brandPrimary)
                }
            }
        }
    }
    
    private func isCurrentSelectedMonth(month: Int) -> Bool {
        calendar.component(.month, from: currentMonth) == month &&
        calendar.component(.year, from: currentMonth) == selectedYear
    }
    
    private func dateFor(month: Int, year: Int) -> Date? {
        var comp = DateComponents()
        comp.year = year
        comp.month = month
        comp.day = 1
        return calendar.date(from: comp)
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
    var onTap: (() -> Void)? = nil
    
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
            
            // Event info — тап открывает детали
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
            
            // Actions
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

// MARK: - Event Detail Sheet

private struct EventDetailSheet: View {
    let event: CalendarState.CalendarEvent
    let model: CalendarView.Model
    let onDismiss: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    private static var dateFormatter: DateFormatter {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ru_RU")
        f.dateFormat = "EEEE, d MMMM yyyy 'г.'"
        return f
    }
    
    private static var timeFormatter: DateFormatter {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ru_RU")
        f.timeStyle = .short
        return f
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
                    // Карточка заголовка с акцентом типа
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
                    
                    // Тип, напоминание, пожелание — в одной карточке
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
        onEditEvent: { _ in },
        onSyncCompleted: { _ in },
        eventCreationModel: .init(
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
        )
    ))
}
