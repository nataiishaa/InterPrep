//
//  CalendarView.swift
//  InterPrep
//
//  Calendar screen with swipeable calendar
//

import DesignSystem
import NetworkMonitorService
import SwiftUI

struct CalendarView: View {
    let model: Model
    @State private var showCalDAVSettings = false
    @State private var lastCalDAVOpenTime: Date = .distantPast
    @State private var showMonthYearPicker = false
    @State private var selectedEventForDetail: CalendarState.CalendarEvent?
    @State private var isSyncing = false
    @State private var showOfflineToast = false
    @ObservedObject private var networkMonitor = NetworkMonitor.shared
    @Environment(\.colorScheme) var colorScheme
    
    private var isOffline: Bool {
        !networkMonitor.isConnected || model.isOfflineMode
    }
    
    var body: some View {
        VStack(spacing: 0) {
            if model.errorMessage != nil && model.events.isEmpty {
                NoConnectionView(onRetry: model.onRetry)
            } else {
                if model.isOfflineMode {
                    OfflineBanner(showCachedHint: true)
                }
                header
                calendarGrid
                eventsList
            }
        }
        .background(Color.backgroundPrimary)
        .safeAreaInset(edge: .bottom) {
            Color.clear.frame(height: 60)
        }
        .overlay(alignment: .bottom) {
            if showOfflineToast {
                Text("Нет интернета — действие недоступно")
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color.black.opacity(0.8))
                    .cornerRadius(12)
                    .padding(.bottom, 80)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: showOfflineToast)
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
        }, content: {
            CalDAVSettingsView(
                settings: CalDAVSettingsManager.shared.loadSettings(),
                onSave: { settings in
                    CalDAVSettingsManager.shared.saveSettings(settings)
                    if settings.isEnabled {
                        performSync()
                    }
                }
            )
        })
    }
    
    // MARK: - Header
    
    @ViewBuilder
    private var header: some View {
        VStack(spacing: 0) {
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
                    if isOffline {
                        showOfflineToast = true
                        Task {
                            try? await Task.sleep(nanoseconds: 2_500_000_000)
                            showOfflineToast = false
                        }
                    } else {
                        model.onCreateEventTapped()
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus.circle.fill")
                        Text("Добавить")
                    }
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(isOffline ? .secondary : .brandPrimary)
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
                
                await MainActor.run {
                    model.onSyncCompleted(syncedEvents)
                    isSyncing = false
                }
            } catch {
                await MainActor.run {
                    isSyncing = false
                }
            }
        }
    }
}

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
        isOfflineMode: false,
        errorMessage: nil,
        onDateSelected: { _ in },
        onMonthChanged: { _ in },
        onCreateEventTapped: {},
        onCancelEventCreation: {},
        onDeleteEvent: { _ in },
        onEditEvent: { _ in },
        onSyncCompleted: { _ in },
        onRetry: {},
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
