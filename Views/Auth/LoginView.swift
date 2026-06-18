import SwiftUI
import UIKit

private enum LoginField: Hashable {
    case email
    case password
}

struct LoginView: View {
    @Environment(\.dismiss) private var dismiss

    let onAuthenticated: () -> Void
    let onBack: (() -> Void)?
    let pendingFirstName: String
    let pendingLastName: String
    let pendingUsername: String

    private let authService = AuthService()
    private let accentPink = Color(red: 1.0, green: 0.22, blue: 0.62)
    private let fieldFill = Color(red: 0.94, green: 0.73, blue: 0.72)

    @State private var email: String
    @State private var password = ""
    @State private var message: String?
    @State private var isPasswordVisible = false
    @State private var isSubmitting = false
    @State private var isSendingReset = false
    @State private var typedGreeting = ""
    @State private var titleTypingTask: Task<Void, Never>?
    @State private var isVisible = false
    @State private var isShowingResetPopup = false
    @State private var resetEmail = ""
    @State private var resetMessage: String?

    @FocusState private var focusedField: LoginField?

    init(
        prefilledEmail: String = "",
        message: String? = nil,
        pendingFirstName: String = "",
        pendingLastName: String = "",
        pendingUsername: String = "",
        onAuthenticated: @escaping () -> Void = {},
        onBack: (() -> Void)? = nil
    ) {
        _email = State(initialValue: prefilledEmail)
        _message = State(initialValue: message)
        self.pendingFirstName = pendingFirstName
        self.pendingLastName = pendingLastName
        self.pendingUsername = pendingUsername
        self.onAuthenticated = onAuthenticated
        self.onBack = onBack
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Image("JBIBackground")
                    .resizable()
                    .scaledToFill()
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .clipped()
                    .ignoresSafeArea()

                backButton(in: geometry)

                VStack(spacing: 18) {
                    titleStack

                    VStack(spacing: 12) {
                        loginField(
                            placeholder: "email",
                            text: $email,
                            field: .email,
                            keyboardType: .emailAddress,
                            width: fieldWidth(for: geometry.size.width)
                        )

                        passwordField(width: fieldWidth(for: geometry.size.width))

                        Text(message ?? " ")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.white.opacity(0.86))
                            .multilineTextAlignment(.center)
                            .frame(width: min(geometry.size.width * 0.78, 320))
                            .frame(minHeight: 18)

                        Button(action: login) {
                            Text(isSubmitting ? "entering" : "enter")
                                .font(.system(size: 16, weight: .heavy))
                                .foregroundStyle(.white)
                                .frame(width: 132, height: 40)
                                .background(accentPink.opacity(isLoginEnabled ? 0.95 : 0.45))
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                        .disabled(!isLoginEnabled || isSubmitting)

                        Button(action: openResetPopup) {
                            Text("forgot password?")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(.white.opacity(0.82))
                        }
                        .buttonStyle(.plain)
                        .padding(.top, 2)
                    }
                }
                .position(x: geometry.size.width / 2, y: geometry.size.height * contentYRatio(for: geometry.size.height))

                if isShowingResetPopup {
                    passwordResetPopup(in: geometry)
                        .zIndex(2)
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .contentShape(Rectangle())
            .onTapGesture {
                focusedField = nil
                hideKeyboard()
            }
        }
        .ignoresSafeArea()
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            isVisible = true
            startTitleTyping()
        }
        .onDisappear {
            isVisible = false
            titleTypingTask?.cancel()
            titleTypingTask = nil
        }
    }

    private var titleStack: some View {
        VStack(spacing: 0) {
            Text(typedGreeting.isEmpty ? " " : typedGreeting)
                .font(.system(size: 36, weight: .heavy))
                .foregroundStyle(.white)

            Text("LOG IN BY")
                .font(.system(size: 26, weight: .heavy))
                .foregroundStyle(.white)
                .padding(.top, 2)

            Text("EMAIL")
                .font(.system(size: 42, weight: .heavy))
                .foregroundStyle(accentPink)
                .padding(.top, 2)

            Text("AND")
                .font(.system(size: 26, weight: .heavy))
                .foregroundStyle(.white)
                .padding(.top, -2)

            Text("PASSWORD")
                .font(.system(size: 42, weight: .heavy))
                .foregroundStyle(accentPink)
                .padding(.top, -2)
        }
        .multilineTextAlignment(.center)
        .lineLimit(1)
        .minimumScaleFactor(0.82)
    }

    private func backButton(in geometry: GeometryProxy) -> some View {
        Button {
            goBack()
        } label: {
            Image(systemName: "chevron.right")
                .font(.system(size: 15, weight: .heavy))
                .foregroundStyle(.black.opacity(0.75))
                .frame(width: 44, height: 44)
                .background(.ultraThinMaterial)
                .background(Color.white.opacity(0.56))
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.35), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .position(x: geometry.size.width - 34, y: geometry.safeAreaInsets.top + 72)
    }

    private func loginField(
        placeholder: String,
        text: Binding<String>,
        field: LoginField,
        keyboardType: UIKeyboardType,
        width: CGFloat
    ) -> some View {
        TextField("", text: text, prompt: Text(placeholder).foregroundStyle(.black.opacity(0.46)))
            .keyboardType(keyboardType)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled(true)
            .textContentType(field == .email ? .emailAddress : .password)
            .focused($focusedField, equals: field)
            .submitLabel(field == .email ? .next : .done)
            .onSubmit {
                if field == .email {
                    focusedField = .password
                } else {
                    focusedField = nil
                    login()
                }
            }
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(.black.opacity(0.82))
            .multilineTextAlignment(.center)
            .textFieldStyle(.plain)
            .padding(.horizontal, 22)
            .frame(width: width, height: 46)
            .background(fieldFill)
            .clipShape(Capsule())
    }

    private func passwordField(width: CGFloat) -> some View {
        ZStack(alignment: .trailing) {
            Capsule()
                .fill(fieldFill)
                .frame(width: width, height: 46)

            Group {
                if isPasswordVisible {
                    TextField("", text: $password, prompt: Text("password").foregroundStyle(.black.opacity(0.46)))
                } else {
                    SecureField("", text: $password, prompt: Text("password").foregroundStyle(.black.opacity(0.46)))
                }
            }
            .textContentType(.password)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled(true)
            .focused($focusedField, equals: .password)
            .submitLabel(.done)
            .onSubmit {
                focusedField = nil
                login()
            }
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(.black.opacity(0.82))
            .multilineTextAlignment(.center)
            .textFieldStyle(.plain)
            .padding(.leading, 24)
            .padding(.trailing, 52)
            .frame(width: width, height: 46)

            Button {
                isPasswordVisible.toggle()
            } label: {
                Image(systemName: isPasswordVisible ? "eye.slash.fill" : "eye.fill")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(.black.opacity(0.62))
                    .frame(width: 36, height: 36)
            }
            .buttonStyle(.plain)
            .padding(.trailing, 11)
        }
        .frame(width: width, height: 46)
    }

    private var isLoginEnabled: Bool {
        isEmailValid(email) && !password.isEmpty && !isSubmitting
    }

    private func fieldWidth(for width: CGFloat) -> CGFloat {
        min(max(width * 0.72, 250), 300)
    }

    private func contentYRatio(for height: CGFloat) -> CGFloat {
        height <= 700 ? 0.53 : 0.50
    }

    private func login() {
        guard isLoginEnabled else { return }

        focusedField = nil
        hideKeyboard()
        isSubmitting = true
        message = nil

        Task {
            do {
                try await authService.signIn(email: email, password: password)
                if hasPendingSignupProfile {
                    try await authService.completeProfileForCurrentSession(
                        firstName: pendingFirstName,
                        lastName: pendingLastName,
                        username: pendingUsername,
                        email: email
                    )
                }
                await MainActor.run {
                    isSubmitting = false
                    onAuthenticated()
                    dismiss()
                }
            } catch let error as AuthServiceError {
                await MainActor.run {
                    isSubmitting = false
                    message = error.localizedDescription
                }
            } catch {
                print("login failed:", error)
                await MainActor.run {
                    isSubmitting = false
                    message = "Email or password is incorrect."
                }
            }
        }
    }

    private func goBack() {
        focusedField = nil
        hideKeyboard()

        if let onBack {
            onBack()
        } else {
            dismiss()
        }
    }

    private var hasPendingSignupProfile: Bool {
        !pendingFirstName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
            !pendingLastName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
            !pendingUsername.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func startTitleTyping() {
        titleTypingTask?.cancel()
        titleTypingTask = nil
        typedGreeting = ""

        titleTypingTask = Task { @MainActor in
            let haptic = UIImpactFeedbackGenerator(style: .light)
            haptic.prepare()

            await type("HELLO AGAIN!", haptic: haptic) { typedGreeting.append($0) }
        }
    }

    @MainActor
    private func type(
        _ text: String,
        haptic: UIImpactFeedbackGenerator,
        append: @escaping (Character) -> Void
    ) async {
        for character in text {
            guard !Task.isCancelled && isVisible else { return }
            append(character)
            haptic.impactOccurred(intensity: 0.45)
            haptic.prepare()
            try? await Task.sleep(nanoseconds: 42_000_000)
        }
        try? await Task.sleep(nanoseconds: 90_000_000)
    }

    private func passwordResetPopup(in geometry: GeometryProxy) -> some View {
        ZStack {
            Color.black.opacity(0.35)
                .ignoresSafeArea()
                .onTapGesture {
                    isShowingResetPopup = false
                    resetMessage = nil
                    hideKeyboard()
                }

            VStack(spacing: 13) {
                HStack {
                    Text("RESET PASSWORD")
                        .font(.system(size: 22, weight: .heavy))
                        .foregroundStyle(.white)

                    Spacer()

                    Button {
                        isShowingResetPopup = false
                        resetMessage = nil
                        hideKeyboard()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 13, weight: .heavy))
                            .foregroundStyle(.white)
                            .frame(width: 32, height: 32)
                            .background(Color.white.opacity(0.16))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }

                Text("Enter your email and we'll send a reset link.")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.white.opacity(0.86))
                    .multilineTextAlignment(.center)

                TextField("", text: $resetEmail, prompt: Text("email").foregroundStyle(.black.opacity(0.46)))
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled(true)
                    .textContentType(.emailAddress)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.black.opacity(0.82))
                    .multilineTextAlignment(.center)
                    .textFieldStyle(.plain)
                    .padding(.horizontal, 22)
                    .frame(width: min(geometry.size.width * 0.72, 300), height: 44)
                    .background(fieldFill)
                    .clipShape(Capsule())

                Text(resetMessage ?? " ")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white.opacity(0.84))
                    .multilineTextAlignment(.center)
                    .frame(width: min(geometry.size.width * 0.76, 310))
                    .frame(minHeight: 18)

                Button(action: sendPasswordReset) {
                    Text(isSendingReset ? "sending" : "Send reset link")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 160, height: 38)
                        .background(accentPink.opacity(isSendingReset ? 0.5 : 0.95))
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .disabled(isSendingReset)
            }
            .padding(22)
            .frame(width: geometry.size.width * 0.9)
            .background {
                ZStack {
                    RoundedRectangle(cornerRadius: 34, style: .continuous)
                        .fill(.ultraThinMaterial)

                    RoundedRectangle(cornerRadius: 34, style: .continuous)
                        .fill(Color(red: 0.45, green: 0.05, blue: 0.45).opacity(0.42))
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: 34, style: .continuous)
                    .stroke(Color.white.opacity(0.28), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 34, style: .continuous))
            .shadow(color: .black.opacity(0.3), radius: 24, x: 0, y: 12)
        }
        .frame(width: geometry.size.width, height: geometry.size.height)
        .ignoresSafeArea()
    }

    private func openResetPopup() {
        resetEmail = email
        resetMessage = nil
        focusedField = nil
        hideKeyboard()
        isShowingResetPopup = true
    }

    private func sendPasswordReset() {
        guard isEmailValid(resetEmail) else {
            resetMessage = "Enter a valid email."
            return
        }

        focusedField = nil
        hideKeyboard()
        isSendingReset = true
        resetMessage = nil

        Task {
            do {
                try await authService.sendPasswordReset(email: resetEmail)
                await MainActor.run {
                    isSendingReset = false
                    resetMessage = "Check your email for a password reset link."
                }
            } catch {
                print("password reset failed:", error)
                await MainActor.run {
                    isSendingReset = false
                    resetMessage = "We could not send the email. Try again in a minute."
                }
            }
        }
    }

    private func isEmailValid(_ value: String) -> Bool {
        let email = value.trimmingCharacters(in: .whitespacesAndNewlines)
        let parts = email.split(separator: "@", omittingEmptySubsequences: false)
        return parts.count == 2 &&
            !parts[0].isEmpty &&
            !parts[1].isEmpty &&
            parts[1].contains(".") &&
            !email.contains(" ")
    }
}

#Preview {
    NavigationStack {
        LoginView(
            prefilledEmail: "drew@example.com",
            message: "Looks like you already have an account. Log in instead."
        )
    }
}
