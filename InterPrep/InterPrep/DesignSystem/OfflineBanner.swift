//
//  OfflineBanner.swift
//  InterPrep
//
//  Compact banner shown at the top of a screen when there is no internet connection.
//

import DesignSystem
import SwiftUI

public struct OfflineBanner: View {
    var hasPendingSync: Bool
    var showCachedHint: Bool

    public init(hasPendingSync: Bool = false, showCachedHint: Bool = false) {
        self.hasPendingSync = hasPendingSync
        self.showCachedHint = showCachedHint
    }

    public var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "wifi.slash")
                .font(.system(size: 14, weight: .medium))

            Text(bannerText)
                .font(.system(size: 13, weight: .medium))
                .lineLimit(1)

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

    private var bannerText: String {
        if hasPendingSync {
            return "Нет сети. Изменения синхронизируются позже"
        }
        if showCachedHint {
            return "Нет сети — показаны сохранённые данные"
        }
        return "Нет подключения к интернету"
    }
}

#Preview {
    VStack {
        OfflineBanner()
        OfflineBanner(hasPendingSync: true)
        OfflineBanner(showCachedHint: true)
    }
}
