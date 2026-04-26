//
//  CalendarDayCell.swift
//  InterPrep
//
//  Single day cell in the month grid
//

import DesignSystem
import SwiftUI

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
