//
//  OfflineBanner.swift
//  InterPrep
//
//  Offline mode indicator banner
//

import SwiftUI
import DesignSystem

struct OfflineBanner: View {
    let hasPendingSync: Bool
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "wifi.slash")
                .font(.system(size: 14, weight: .medium))
            
            Text(hasPendingSync ? "Нет подключения. Изменения будут синхронизированы позже." : "Нет подключения к интернету")
                .font(.system(size: 13, weight: .medium))
            
            Spacer()
            
            if hasPendingSync {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 14))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color.orange.opacity(0.9))
        .foregroundColor(.white)
    }
}

#Preview {
    VStack {
        OfflineBanner(hasPendingSync: false)
        OfflineBanner(hasPendingSync: true)
    }
}
