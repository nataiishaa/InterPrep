//
//  MonthYearPickerView.swift
//  InterPrep
//
//  Sheet for picking month and year on the calendar screen
//

import DesignSystem
import SwiftUI

struct MonthYearPickerView: View {
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
