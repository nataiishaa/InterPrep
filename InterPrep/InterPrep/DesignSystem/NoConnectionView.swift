//
//  NoConnectionView.swift
//  InterPrep
//
//  Full-screen placeholder shown when there is no internet and no cached data
//

import DesignSystem
import SwiftUI

public struct NoConnectionView: View {
    let onRetry: () -> Void
    var message: String
    var subtitle: String

    public init(
        onRetry: @escaping () -> Void,
        message: String = "Проблемы с подключением к интернету.",
        subtitle: String = "Попробуйте позже."
    ) {
        self.onRetry = onRetry
        self.message = message
        self.subtitle = subtitle
    }
    
    public var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(Color.brandPrimary.opacity(0.08))
                    .frame(width: 120, height: 120)
                
                Image(systemName: "wifi.slash")
                    .font(.system(size: 44, weight: .medium))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.brandPrimary, .brandSecondary],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            
            VStack(spacing: 8) {
                Text(message)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.textOnBackground)
                    .multilineTextAlignment(.center)
                
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 32)
            
            Button(action: onRetry) {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.clockwise")
                        .font(.subheadline.weight(.semibold))
                    Text("Попробовать снова")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: 260)
                .padding(.vertical, 14)
                .background(
                    LinearGradient(
                        colors: [.brandPrimary, .brandSecondary],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(14)
                .shadow(color: .brandPrimary.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.backgroundPrimary)
    }
}

#Preview {
    NoConnectionView(onRetry: {})
}
