import SwiftUI

public struct NoConnectionView: View {
    let onRetry: () -> Void
    var message: String
    var subtitle: String
    var isVPNLikely: Bool
    var hasPendingSync: Bool

    public init(
        onRetry: @escaping () -> Void,
        message: String = "Проблемы с подключением к интернету.",
        subtitle: String = "Попробуйте позже.",
        isVPNLikely: Bool = false,
        hasPendingSync: Bool = false
    ) {
        self.onRetry = onRetry
        self.message = message
        self.subtitle = subtitle
        self.isVPNLikely = isVPNLikely
        self.hasPendingSync = hasPendingSync
    }

    @_disfavoredOverload
    public init(
        onRetry: @escaping () -> Void,
        message: String,
        subtitle: String
    ) {
        self.onRetry = onRetry
        self.message = message
        self.subtitle = subtitle
        self.isVPNLikely = false
        self.hasPendingSync = false
    }

    public var body: some View {
        VStack(spacing: 24) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Color.brandPrimary.opacity(0.08))
                    .frame(width: 120, height: 120)

                Image(systemName: iconName)
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
                Text(displayMessage)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.textOnBackground)
                    .multilineTextAlignment(.center)

                Text(displaySubtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 32)

            if hasPendingSync {
                HStack(spacing: 8) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 14))
                    Text("Есть несинхронизированные изменения")
                        .font(.footnote)
                }
                .foregroundColor(.orange)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(8)
            }

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

    private var iconName: String {
        isVPNLikely ? "network.slash" : "wifi.slash"
    }

    private var displayMessage: String {
        if !message.isEmpty { return message }
        return isVPNLikely
            ? "Кажется, у вас включён VPN"
            : "Нет подключения к интернету"
    }

    private var displaySubtitle: String {
        if !subtitle.isEmpty { return subtitle }
        return isVPNLikely
            ? "Отключите VPN и попробуйте снова"
            : "Проверьте соединение и попробуйте снова"
    }
}

public extension NoConnectionView {
    static func makeForNoInternet(
        onRetry: @escaping () -> Void,
        hasPendingSync: Bool = false
    ) -> NoConnectionView {
        NoConnectionView(
            onRetry: onRetry,
            message: "Нет подключения к интернету",
            subtitle: "Проверьте соединение и попробуйте снова",
            isVPNLikely: false,
            hasPendingSync: hasPendingSync
        )
    }

    static func makeForVPNLikely(
        onRetry: @escaping () -> Void,
        hasPendingSync: Bool = false
    ) -> NoConnectionView {
        NoConnectionView(
            onRetry: onRetry,
            message: "Кажется, у вас включён VPN",
            subtitle: "Отключите VPN и попробуйте снова",
            isVPNLikely: true,
            hasPendingSync: hasPendingSync
        )
    }
}

#Preview {
    VStack {
        NoConnectionView(onRetry: {})
        NoConnectionView(onRetry: {}, isVPNLikely: true, hasPendingSync: true)
    }
}
