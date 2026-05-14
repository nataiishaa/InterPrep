import SwiftUI

struct RegistrationDetailsView: View {
    let model: Model
    @FocusState private var focusedField: Field?

    private let gradientColorLight = Color(red: 0.45, green: 0.5, blue: 0.45)
    private let gradientColorDark = Color(red: 0.35, green: 0.4, blue: 0.35)

    enum Field {
        case email, password, passwordConfirm
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
                            .fill(Color.white.opacity(Layout.inactiveOpacity))
                            .frame(width: Layout.indicatorWidth, height: Layout.indicatorHeight)

                        Circle()
                            .fill(Color.white)
                            .frame(width: Layout.indicatorWidth, height: Layout.indicatorHeight)
                    }
                    .padding(.top, Layout.indicatorTopPadding)

                    Spacer()
                        .frame(height: Layout.titleSpacerHeight)

                    Text("Регистрация")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.bottom, Layout.titleBottomPadding)

                    VStack(spacing: Layout.fieldSpacing) {
                        CustomTextField(
                            placeholder: "Почта",
                            text: Binding(
                                get: { model.email },
                                set: { model.onEmailChanged($0) }
                            ),
                            keyboardType: .emailAddress
                        )
                        .focused($focusedField, equals: .email)
                        .submitLabel(.next)
                        .onSubmit { focusedField = .password }

                        CustomTextField(
                            placeholder: "Пароль",
                            text: Binding(
                                get: { model.password },
                                set: { model.onPasswordChanged($0) }
                            ),
                            isSecure: true
                        )
                        .focused($focusedField, equals: .password)
                        .submitLabel(.next)
                        .onSubmit { focusedField = .passwordConfirm }

                        CustomTextField(
                            placeholder: "Повторите пароль",
                            text: Binding(
                                get: { model.passwordConfirm },
                                set: { model.onPasswordConfirmChanged($0) }
                            ),
                            isSecure: true
                        )
                        .focused($focusedField, equals: .passwordConfirm)
                        .submitLabel(.go)
                        .onSubmit { model.onSubmit() }
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
                        model.onSubmit()
                    } label: {
                        if model.isLoading {
                            ProgressView()
                                .tint(gradientColorDark)
                        } else {
                            Text("Зарегистрироваться")
                                .font(.headline)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: Layout.buttonHeight)
                    .background(Color.white)
                    .foregroundColor(gradientColorDark)
                    .cornerRadius(Layout.buttonCornerRadius)
                    .disabled(model.isLoading)
                    .padding(.horizontal, Layout.horizontalPadding)
                    .padding(.bottom, Layout.buttonBottomPadding)
                }
            }
        }
    }
}

private extension RegistrationDetailsView {
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
    RegistrationDetailsView(model: .init(
        email: "",
        password: "",
        passwordConfirm: "",
        isLoading: false,
        errorMessage: nil,
        onEmailChanged: { _ in },
        onPasswordChanged: { _ in },
        onPasswordConfirmChanged: { _ in },
        onSubmit: {}
    ))
}
