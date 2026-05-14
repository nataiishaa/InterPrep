import SwiftUI

struct RegistrationView: View {
    let model: Model
    @FocusState private var focusedField: Field?

    private let gradientColorLight = Color(red: 0.45, green: 0.5, blue: 0.45)
    private let gradientColorDark = Color(red: 0.35, green: 0.4, blue: 0.35)

    enum Field {
        case firstName, lastName
    }

    init(model: Model) {
        self.model = model
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            LinearGradient(
                colors: [gradientColorLight, gradientColorDark],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: Layout.contentSpacing) {
                    HStack(spacing: Layout.indicatorSpacing) {
                        Circle()
                            .fill(Color.white)
                            .frame(width: Layout.indicatorWidth, height: Layout.indicatorHeight)

                        Circle()
                            .fill(Color.white.opacity(Layout.inactiveOpacity))
                            .frame(width: Layout.indicatorWidth, height: Layout.indicatorHeight)
                    }
                    .padding(.top, Layout.indicatorTopPadding)

                    Spacer()
                        .frame(height: Layout.titleSpacerHeight)

                    Text("Давайте знакомиться!\nКак вас зовут?")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.white)
                        .padding(.bottom, Layout.titleBottomPadding)

                    VStack(spacing: Layout.fieldSpacing) {
                        CustomTextField(
                            placeholder: "Имя",
                            text: Binding(
                                get: { model.firstName },
                                set: { model.onFirstNameChanged($0) }
                            )
                        )
                        .focused($focusedField, equals: .firstName)
                        .submitLabel(.next)
                        .onSubmit { focusedField = .lastName }

                        CustomTextField(
                            placeholder: "Фамилия",
                            text: Binding(
                                get: { model.lastName },
                                set: { model.onLastNameChanged($0) }
                            )
                        )
                        .focused($focusedField, equals: .lastName)
                        .submitLabel(.continue)
                        .onSubmit { model.onContinue() }
                    }
                    .padding(.horizontal, Layout.horizontalPadding)

                    if let errorMessage = model.errorMessage {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding(.horizontal, Layout.horizontalPadding)
                            .transition(.opacity)
                    }

                    Spacer()

                    Button {
                        model.onContinue()
                    } label: {
                        Text("Продолжить")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .frame(height: Layout.buttonHeight)
                            .background(Color.white)
                            .foregroundColor(gradientColorDark)
                            .cornerRadius(Layout.buttonCornerRadius)
                    }
                    .padding(.horizontal, Layout.horizontalPadding)
                    .padding(.bottom, Layout.buttonBottomPadding)
                }
            }
        }
    }
}

private extension RegistrationView {
    enum Layout {
        static let contentSpacing: CGFloat = 24
        static let indicatorSpacing: CGFloat = 8
        static let indicatorWidth: CGFloat = 30
        static let indicatorHeight: CGFloat = 4
        static let indicatorTopPadding: CGFloat = 60
        static let titleSpacerHeight: CGFloat = 20
        static let titleBottomPadding: CGFloat = 40
        static let fieldSpacing: CGFloat = 16
        static let horizontalPadding: CGFloat = 32
        static let buttonHeight: CGFloat = 50
        static let buttonCornerRadius: CGFloat = 12
        static let buttonBottomPadding: CGFloat = 20
        static let inactiveOpacity: Double = 0.3
    }
}

#Preview {
    RegistrationView(model: .init(
        firstName: "",
        lastName: "",
        errorMessage: nil,
        onFirstNameChanged: { _ in },
        onLastNameChanged: { _ in },
        onContinue: {}
    ))
}
