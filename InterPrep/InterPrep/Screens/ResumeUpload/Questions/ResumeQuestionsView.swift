import DesignSystem
import SwiftUI

public struct ResumeQuestionsView: View {
    let model: Model

    public init(model: Model) {
        self.model = model
    }

    public var body: some View {
        VStack(spacing: 0) {
            header

            if !model.questions.isEmpty {
                questionContent
                bottomButtons
            }
        }
        .background(LinearGradient.brandBackground)
    }

    @ViewBuilder
    private var header: some View {
        VStack(spacing: 16) {
            HStack {
                Spacer()
                Button("Пропустить") {
                    model.onSkip()
                }
                .foregroundColor(.white.opacity(0.7))
                .font(.subheadline)
                .padding(.horizontal, 20)
                .padding(.top, 16)
            }

            progressIndicator
        }
    }

    @ViewBuilder
    private var progressIndicator: some View {
        VStack(spacing: 12) {
            HStack(spacing: 6) {
                ForEach(0..<model.questions.count, id: \.self) { index in
                    Capsule()
                        .fill(index <= model.currentQuestionIndex ? Color.white : Color.white.opacity(0.3))
                        .frame(height: 4)
                        .animation(.easeInOut(duration: 0.3), value: model.currentQuestionIndex)
                }
            }
            .padding(.horizontal, 24)

            Text("\(model.currentQuestionIndex + 1) из \(model.questions.count)")
                .font(.caption)
                .foregroundColor(.white.opacity(0.6))
        }
    }

    @ViewBuilder
    private var questionContent: some View {
        let safeIndex = min(model.currentQuestionIndex, model.questions.count - 1)
        let question = model.questions[max(0, safeIndex)]

        ScrollView {
            VStack(spacing: 24) {
                if let error = model.errorMessage {
                    errorBanner(error)
                }

                questionView(question: question)
            }
            .padding(.horizontal, 24)
            .padding(.top, 32)
        }
        .id(question.id)
        .transition(.asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)
        ))
    }

    @ViewBuilder
    private func errorBanner(_ error: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.red)
            Text(error)
                .font(.subheadline)
                .foregroundColor(.red)
            Spacer()
        }
        .padding(16)
        .background(Color.red.opacity(0.15))
        .cornerRadius(12)
    }

    @ViewBuilder
    private func questionView(question: ResumeQuestion) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                questionIcon(for: question.id)

                Text(question.text)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .fixedSize(horizontal: false, vertical: true)
            }

            answerInput(for: question)
        }
    }

    @ViewBuilder
    private func questionIcon(for questionId: String) -> some View {
        Image(systemName: iconName(for: questionId))
            .font(.system(size: 44))
            .foregroundColor(.white.opacity(0.9))
            .padding(.bottom, 8)
    }

    private func iconName(for questionId: String) -> String {
        switch questionId {
        case "areas":
            return "mappin.circle.fill"
        case "work_format":
            return "building.2.fill"
        case "salary_min":
            return "banknote.fill"
        default:
            return "questionmark.circle.fill"
        }
    }

    @ViewBuilder
    private func answerInput(for question: ResumeQuestion) -> some View {
        if question.type == "numeric_input" {
            NumericInputAnswer(
                question: question,
                value: model.answers[question.id] ?? "",
                onChanged: { model.onAnswerChanged(question.id, $0) }
            )
        } else {
            SingleChoiceAnswer(
                question: question,
                selectedValue: model.answers[question.id] ?? "",
                onChanged: { model.onAnswerChanged(question.id, $0) }
            )
        }
    }

    @ViewBuilder
    private var bottomButtons: some View {
        let safeIndex = min(model.currentQuestionIndex, model.questions.count - 1)
        let currentQuestion = model.questions[max(0, safeIndex)]
        let hasAnswer = !(model.answers[currentQuestion.id] ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let isLastQuestion = safeIndex == model.questions.count - 1

        VStack(spacing: 12) {
            Button {
                if isLastQuestion {
                    model.onSubmit()
                } else {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        model.onNextQuestion()
                    }
                }
            } label: {
                HStack(spacing: 8) {
                    if model.isSubmitting {
                        ProgressView()
                            .tint(.brandPrimary)
                            .scaleEffect(0.9)
                    } else {
                        Text(isLastQuestion ? "Готово" : "Далее")
                            .font(.headline)

                        if !isLastQuestion {
                            Image(systemName: "arrow.right")
                                .font(.subheadline)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(hasAnswer ? Color.white : Color.white.opacity(0.5))
                .foregroundColor(.brandPrimary)
                .cornerRadius(16)
            }
            .disabled(model.isSubmitting || !hasAnswer)

            if model.currentQuestionIndex > 0 {
                Button {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        model.onPreviousQuestion()
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.left")
                            .font(.caption)
                        Text("Назад")
                            .font(.subheadline)
                    }
                    .foregroundColor(.white.opacity(0.7))
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 32)
        .padding(.top, 16)
    }
}

private struct SingleChoiceAnswer: View {
    let question: ResumeQuestion
    let selectedValue: String
    let onChanged: (String) -> Void

    var body: some View {
        VStack(spacing: 10) {
            ForEach(question.options, id: \.self) { option in
                OptionButton(
                    displayText: option,
                    isSelected: selectedValue == option,
                    onTap: { onChanged(option) }
                )
            }
        }
    }
}

private struct NumericInputAnswer: View {
    let question: ResumeQuestion
    let value: String
    let onChanged: (String) -> Void

    @State private var customValue: String = ""
    @FocusState private var isFieldFocused: Bool

    private var isCustomInput: Bool {
        !value.isEmpty && !question.options.contains(value)
    }

    var body: some View {
        VStack(spacing: 16) {
            presetButtons

            dividerRow

            customInputField
        }
    }

    @ViewBuilder
    private var presetButtons: some View {
        VStack(spacing: 10) {
            ForEach(question.options, id: \.self) { option in
                OptionButton(
                    displayText: formatSalary(option),
                    isSelected: value == option,
                    onTap: {
                        customValue = ""
                        isFieldFocused = false
                        onChanged(option)
                    }
                )
            }
        }
    }

    @ViewBuilder
    private var dividerRow: some View {
        HStack(spacing: 12) {
            Rectangle()
                .fill(Color.white.opacity(0.2))
                .frame(height: 1)
            Text("или")
                .font(.caption)
                .foregroundColor(.white.opacity(0.5))
            Rectangle()
                .fill(Color.white.opacity(0.2))
                .frame(height: 1)
        }
    }

    @ViewBuilder
    private var customInputField: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                TextField("Своя сумма", text: $customValue)
                    .font(.body)
                    .foregroundColor(.white)
                    .tint(.white)
                    .keyboardType(.numberPad)
                    .focused($isFieldFocused)

                Text("₽")
                    .font(.body)
                    .foregroundColor(.white.opacity(0.6))
            }
            .padding(16)
            .background(isCustomInput ? Color.white.opacity(0.25) : Color.white.opacity(0.1))
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isCustomInput ? Color.white.opacity(0.4) : Color.clear, lineWidth: 1)
            )
            .onChange(of: customValue) { _, newValue in
                let filtered = newValue.filter { $0.isNumber }
                if filtered != customValue {
                    customValue = filtered
                }
                if !filtered.isEmpty {
                    onChanged(filtered)
                }
            }

            Text("от 1 000 до 10 000 000 ₽")
                .font(.caption)
                .foregroundColor(.white.opacity(0.5))
        }
    }

    private func formatSalary(_ value: String) -> String {
        guard let number = Int(value) else { return value }
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = " "
        let formatted = formatter.string(from: NSNumber(value: number)) ?? value
        return "\(formatted) ₽"
    }
}

private struct OptionButton: View {
    let displayText: String
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : .white.opacity(0.4))

                Text(displayText)
                    .font(.body)
                    .fontWeight(isSelected ? .medium : .regular)
                    .foregroundColor(.white)

                Spacer()
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            .background(isSelected ? Color.white.opacity(0.25) : Color.white.opacity(0.1))
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? Color.white.opacity(0.4) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

#Preview {
    ResumeQuestionsView(model: .preview)
}
