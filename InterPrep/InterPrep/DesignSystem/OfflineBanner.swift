import SwiftUI

public struct OfflineBanner: View {
    var hasPendingSync: Bool
    var showCachedHint: Bool
    var lastUpdated: Date?
    var onRetry: (() -> Void)?

    public init(
        hasPendingSync: Bool = false,
        showCachedHint: Bool = false,
        lastUpdated: Date? = nil,
        onRetry: (() -> Void)? = nil
    ) {
        self.hasPendingSync = hasPendingSync
        self.showCachedHint = showCachedHint
        self.lastUpdated = lastUpdated
        self.onRetry = onRetry
    }

    @_disfavoredOverload
    public init(hasPendingSync: Bool, showCachedHint: Bool) {
        self.hasPendingSync = hasPendingSync
        self.showCachedHint = showCachedHint
        self.lastUpdated = nil
        self.onRetry = nil
    }

    public var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "wifi.slash")
                .font(.system(size: 14, weight: .medium))

            VStack(alignment: .leading, spacing: 2) {
                Text(bannerText)
                    .font(.system(size: 13, weight: .medium))
                    .lineLimit(1)

                if let lastUpdated = lastUpdated {
                    Text(lastUpdatedText(from: lastUpdated))
                        .font(.system(size: 11))
                        .opacity(0.85)
                }
            }

            Spacer()

            if hasPendingSync {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 14))
            }

            if let onRetry = onRetry {
                Button(action: onRetry) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 14, weight: .semibold))
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, lastUpdated != nil ? 8 : 10)
        .background(Color.orange.opacity(0.9))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .foregroundColor(.white)
        .padding(.horizontal, 16)
    }

    private var bannerText: String {
        if hasPendingSync {
            return "Нет сети. Изменения синхронизируются позже"
        }
        if showCachedHint {
            return "Нет сети — показаны сохранённые данные"
        }
        return "Нет интернета"
    }

    private func lastUpdatedText(from date: Date) -> String {
        let interval = Date().timeIntervalSince(date)

        if interval < 60 {
            return "Обновлено только что"
        } else if interval < 3600 {
            let minutes = Int(interval / 60)
            return "Обновлено \(minutes) \(minutesDeclension(minutes)) назад"
        } else if interval < 86400 {
            let hours = Int(interval / 3600)
            return "Обновлено \(hours) \(hoursDeclension(hours)) назад"
        } else {
            let days = Int(interval / 86400)
            return "Обновлено \(days) \(daysDeclension(days)) назад"
        }
    }

    private func minutesDeclension(_ num: Int) -> String {
        let mod10 = num % 10
        let mod100 = num % 100
        if mod10 == 1 && mod100 != 11 { return "минуту" }
        if mod10 >= 2 && mod10 <= 4 && (mod100 < 10 || mod100 >= 20) { return "минуты" }
        return "минут"
    }

    private func hoursDeclension(_ num: Int) -> String {
        let mod10 = num % 10
        let mod100 = num % 100
        if mod10 == 1 && mod100 != 11 { return "час" }
        if mod10 >= 2 && mod10 <= 4 && (mod100 < 10 || mod100 >= 20) { return "часа" }
        return "часов"
    }

    private func daysDeclension(_ num: Int) -> String {
        let mod10 = num % 10
        let mod100 = num % 100
        if mod10 == 1 && mod100 != 11 { return "день" }
        if mod10 >= 2 && mod10 <= 4 && (mod100 < 10 || mod100 >= 20) { return "дня" }
        return "дней"
    }
}

#Preview {
    VStack(spacing: 0) {
        OfflineBanner()
        OfflineBanner(hasPendingSync: true)
        OfflineBanner(showCachedHint: true)
        OfflineBanner(showCachedHint: true, lastUpdated: Date().addingTimeInterval(-3600))
        OfflineBanner(showCachedHint: true, lastUpdated: Date().addingTimeInterval(-7200), onRetry: {})
    }
}
