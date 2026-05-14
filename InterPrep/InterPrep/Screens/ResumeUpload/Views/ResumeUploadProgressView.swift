import DesignSystem
import SwiftUI

public struct ResumeUploadProgressView: View {
    private struct ProgressMessage: Equatable {
        let icon: String
        let title: String
        let subtitle: String
    }

    @State private var currentMessageIndex: Int = 0
    @State private var animatedProgress: Double = 0
    @State private var pulseScale: CGFloat = 1.0
    @State private var iconRotation: Double = 0
    @State private var showCheckmark: Bool = false

    private let isComplete: Bool
    private let timer = Timer.publish(every: 3.0, on: .main, in: .common).autoconnect()

    private let messages: [ProgressMessage] = [
        ProgressMessage(icon: "arrow.up.doc.fill", title: "Загружаем резюме", subtitle: "Передаём ваш файл на сервер"),
        ProgressMessage(icon: "doc.text.magnifyingglass", title: "Читаем резюме", subtitle: "Извлекаем информацию из документа"),
        ProgressMessage(icon: "brain.head.profile", title: "Анализируем опыт", subtitle: "Изучаем ваш профессиональный путь"),
        ProgressMessage(icon: "list.bullet.clipboard", title: "Выделяем навыки", subtitle: "Определяем ключевые компетенции"),
        ProgressMessage(icon: "sparkles", title: "Оцениваем профиль", subtitle: "Сопоставляем с требованиями рынка"),
        ProgressMessage(icon: "person.2.fill", title: "Подбираем вакансии", subtitle: "Ищем идеальные предложения для вас"),
        ProgressMessage(icon: "star.fill", title: "Ранжируем результаты", subtitle: "Сортируем по релевантности"),
        ProgressMessage(icon: "hourglass", title: "Осталось совсем чуть-чуть", subtitle: "Завершаем обработку")
    ]

    public init(isComplete: Bool = false) {
        self.isComplete = isComplete
    }

    public var body: some View {
        VStack(spacing: 40) {
            Spacer()

            iconView

            textSection

            progressDots

            Spacer()
        }
        .padding(.vertical, 32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(LinearGradient.brandBackground)
        .onAppear {
            startAnimations()
        }
        .onReceive(timer) { _ in
            if !isComplete && currentMessageIndex < messages.count - 1 {
                withAnimation(.easeInOut(duration: 0.5)) {
                    currentMessageIndex += 1
                }
                updateProgress()
            }
        }
        .onChange(of: isComplete) { _, complete in
            if complete {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    showCheckmark = true
                    animatedProgress = 1.0
                }
            }
        }
    }

    private var currentMessage: ProgressMessage {
        if isComplete {
            return ProgressMessage(icon: "checkmark.circle.fill", title: "Готово!", subtitle: "Переходим к результатам")
        }
        return messages[currentMessageIndex]
    }

    @ViewBuilder
    private var iconView: some View {
        ZStack {
            Circle()
                .fill(.white.opacity(0.08))
                .frame(width: 140, height: 140)
                .scaleEffect(pulseScale)

            Circle()
                .fill(.white.opacity(0.12))
                .frame(width: 110, height: 110)
                .scaleEffect(pulseScale * 0.95)

            Circle()
                .fill(.white.opacity(0.18))
                .frame(width: 80, height: 80)

            if showCheckmark {
                Image(systemName: "checkmark")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.white)
                    .transition(.scale.combined(with: .opacity))
            } else {
                Image(systemName: currentMessage.icon)
                    .font(.system(size: 36, weight: .medium))
                    .foregroundColor(.white)
                    .rotationEffect(.degrees(currentMessage.icon == "arrow.up.doc.fill" ? iconRotation : 0))
                    .id(currentMessage.icon)
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.5).combined(with: .opacity),
                        removal: .scale(scale: 1.2).combined(with: .opacity)
                    ))
            }
        }
        .animation(.easeInOut(duration: 0.4), value: currentMessage.icon)
    }

    @ViewBuilder
    private var textSection: some View {
        VStack(spacing: 16) {
            Text(currentMessage.title)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .id(currentMessage.title)
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))

            Text(currentMessage.subtitle)
                .font(.body)
                .foregroundColor(.white.opacity(0.85))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .id(currentMessage.subtitle)
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
        }
        .padding(.horizontal, 40)
        .animation(.easeInOut(duration: 0.4), value: currentMessage.title)
    }

    @ViewBuilder
    private var progressDots: some View {
        HStack(spacing: 8) {
            ForEach(0..<messages.count, id: \.self) { index in
                Circle()
                    .fill(index == currentMessageIndex ? .white : .white.opacity(0.3))
                    .frame(width: index == currentMessageIndex ? 10 : 6, height: index == currentMessageIndex ? 10 : 6)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentMessageIndex)
            }
        }
        .padding(.top, 8)
    }

    private func startAnimations() {
        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
            pulseScale = 1.15
        }

        withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: false)) {
            iconRotation = -10
        }

        withAnimation(.easeOut(duration: 0.5)) {
            animatedProgress = 0.1
        }
    }

    private func updateProgress() {
        let baseProgress = Double(currentMessageIndex + 1) / Double(messages.count)
        withAnimation(.easeInOut(duration: 0.5)) {
            animatedProgress = min(baseProgress, 0.95)
        }
    }
}

#Preview("Loading") {
    ResumeUploadProgressView()
}

#Preview("Complete") {
    ResumeUploadProgressView(isComplete: true)
}
