//
//  TypingIndicatorView.swift
//  InterPrep
//
//  Animated "processing request" indicator for chat
//

import DesignSystem
import SwiftUI

struct TypingIndicatorView: View {
    @State private var phase: Int = 0
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(Color.secondary)
                        .frame(width: 7, height: 7)
                        .scaleEffect(phase == index ? 1.3 : 0.8)
                        .opacity(phase == index ? 1.0 : 0.4)
                        .animation(
                            .easeInOut(duration: 0.4)
                                .repeatForever(autoreverses: true)
                                .delay(Double(index) * 0.15),
                            value: phase
                        )
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(bubbleColor)
            )

            Text("Обработка запроса…")
                .font(.caption2)
                .foregroundColor(.secondary)
                .padding(.leading, 8)
        }
        .onAppear {
            phase = 2
        }
    }

    private var bubbleColor: Color {
        colorScheme == .dark ? Color(red: 0.2, green: 0.2, blue: 0.2) : Color(.systemGray5)
    }
}

#Preview {
    VStack {
        TypingIndicatorView()
        Spacer()
    }
    .padding()
}
