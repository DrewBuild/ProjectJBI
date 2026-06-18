import SwiftUI
import UIKit

struct CreateAccountFlowView: View {
    @Environment(\.dismiss) private var dismiss

    let onAuthenticated: () -> Void

    private let authService = AuthService()

    @State private var firstName = ""
    @State private var lastName = ""
    @State private var username = ""
    @State private var password = ""
    @State private var email = ""
    @State private var currentStep = 1
    @State private var isShowingConfirmation = false
    @State private var isShowingLogin = false
    @State private var loginEmail = ""
    @State private var loginMessage: String?
    @State private var shouldLoginCompleteSignupProfile = false
    @State private var attemptedInvalidFirstName = false
    @State private var attemptedInvalidLastName = false
    @State private var isPasswordVisible = false
    @State private var hasAcceptedLegal = false
    @State private var legalDocument: LegalDocument?
    @State private var usernameStatus: UsernameStatus?
    @State private var usernameAvailabilityReason: String?
    @State private var isCheckingUsername = false
    @State private var usernameCheckTask: Task<Void, Never>?
    @State private var serviceErrorText: String?
    @State private var isSendingCode = false
    @State private var isFinishingConfirmation = false
    @State private var isSignupSuccessful = false
    @State private var resendRemainingSeconds = 0
    @State private var resendTask: Task<Void, Never>?

    @FocusState private var focusedField: CreateAccountField?

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Image("JBIBackground")
                    .resizable()
                    .scaledToFill()
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .clipped()
                    .ignoresSafeArea()

                currentStepView

                if let legalDocument {
                    LegalPopupView(document: legalDocument) {
                        self.legalDocument = nil
                    }
                    .zIndex(2)
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .ignoresSafeArea()
        }
        .ignoresSafeArea()
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .navigationDestination(isPresented: $isShowingLogin) {
            LoginView(
                prefilledEmail: loginEmail,
                message: loginMessage,
                pendingFirstName: shouldLoginCompleteSignupProfile ? firstName : "",
                pendingLastName: shouldLoginCompleteSignupProfile ? lastName : "",
                pendingUsername: shouldLoginCompleteSignupProfile ? username : "",
                onAuthenticated: onAuthenticated
            )
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    focusedField = nil
                    hideKeyboard()
                }
            }
        }
        .gesture(
            DragGesture()
                .onEnded { value in
                    guard value.translation.width > 80, abs(value.translation.height) < 80 else { return }
                    back()
                }
        )
        .animation(.spring(response: 0.34, dampingFraction: 0.88), value: isShowingConfirmation)
        .onChange(of: username) { _, _ in
            scheduleUsernameCheck()
        }
        .onDisappear {
            usernameCheckTask?.cancel()
            resendTask?.cancel()
        }
    }

    @ViewBuilder
    private var currentStepView: some View {
        switch currentStep {
        case 1:
            stepView(
                step: 1,
                title: "Welcome to\nJust Bean It.",
                subtitle: "What is your first name?",
                placeholder: "Enter First Name",
                previewText: "",
                field: .firstName,
                helperText: helperText(for: .firstName),
                isNextEnabled: isFirstNameValid,
                text: firstNameBinding
            )
        case 2:
            stepView(
                step: 2,
                title: firstName.isEmpty ? "Hello" : "Hello, \(firstName)",
                subtitle: "What is your last name?",
                placeholder: "Enter Last Name",
                previewText: firstName,
                field: .lastName,
                helperText: helperText(for: .lastName),
                isNextEnabled: isLastNameValid,
                text: lastNameBinding
            )
        case 3:
            stepView(
                step: 3,
                title: "Claim you @",
                subtitle: "create username",
                placeholder: "Enter Username",
                previewText: namePreview,
                field: .username,
                helperText: helperText(for: .username),
                isNextEnabled: isUsernameValidAndAvailable,
                text: usernameBinding
            )
        case 4:
            stepView(
                step: 4,
                title: "Shhhh...",
                subtitle: "create password",
                placeholder: "Enter password",
                previewText: usernamePreview,
                field: .password,
                helperText: helperText(for: .password),
                isNextEnabled: isPasswordValid,
                text: passwordBinding
            )
        default:
            if isShowingConfirmation {
                confirmationStepView
            } else {
                stepView(
                    step: 5,
                    title: "Last but not least\nyour email",
                    subtitle: "choose a good email",
                    placeholder: "Enter email",
                    previewText: usernamePreview,
                    field: .email,
                    helperText: helperText(for: .email),
                    isNextEnabled: isEmailValid && hasAcceptedLegal && !isSendingCode,
                    text: emailBinding
                )
            }
        }
    }

    private func stepView(
        step: Int,
        title: String,
        subtitle: String,
        placeholder: String,
        previewText: String,
        field: CreateAccountField,
        helperText: String?,
        isNextEnabled: Bool,
        text: Binding<String>
    ) -> some View {
        CreateStepView(
            step: step,
            title: title,
            subtitle: subtitle,
            placeholder: placeholder,
            previewText: previewText,
            field: field,
            helperText: helperText,
            serviceErrorText: serviceErrorText,
            usernameStatus: usernameStatus,
            isCheckingUsername: isCheckingUsername,
            passwordRequirements: field == .password ? passwordRequirements : [],
            showsCreationLegalText: false,
            showsAgreementCheckbox: step == 5,
            isNextEnabled: isNextEnabled,
            onBack: back,
            onNext: next,
            onShowTerms: { legalDocument = .terms },
            onShowPrivacy: { legalDocument = .privacy },
            text: text,
            isPasswordVisible: $isPasswordVisible,
            hasAcceptedLegal: $hasAcceptedLegal,
            focusedField: $focusedField
        )
    }

    private var firstNameBinding: Binding<String> {
        Binding(
            get: { firstName },
            set: { newValue in
                let sanitized = lettersOnly(newValue)
                attemptedInvalidFirstName = sanitized != newValue.trimmingCharacters(in: .whitespacesAndNewlines)
                firstName = sanitized
                serviceErrorText = nil
            }
        )
    }

    private var lastNameBinding: Binding<String> {
        Binding(
            get: { lastName },
            set: { newValue in
                let sanitized = lettersOnly(newValue)
                attemptedInvalidLastName = sanitized != newValue.trimmingCharacters(in: .whitespacesAndNewlines)
                lastName = sanitized
                serviceErrorText = nil
            }
        )
    }

    private var usernameBinding: Binding<String> {
        Binding(
            get: { username },
            set: { newValue in
                username = newValue.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                serviceErrorText = nil
            }
        )
    }

    private var passwordBinding: Binding<String> {
        Binding(
            get: { password },
            set: {
                password = $0.trimmingCharacters(in: .whitespacesAndNewlines)
                serviceErrorText = nil
            }
        )
    }

    private var emailBinding: Binding<String> {
        Binding(
            get: { email },
            set: {
                email = $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                serviceErrorText = nil
            }
        )
    }

    private var namePreview: String {
        guard !firstName.isEmpty else { return "" }

        if let initial = lastName.first {
            return "\(firstName) \(String(initial).uppercased())."
        }

        return firstName
    }

    private var usernamePreview: String {
        if namePreview.isEmpty {
            return username.isEmpty ? "" : "@\(username)"
        }

        return username.isEmpty ? namePreview : "\(namePreview) | @\(username)"
    }

    private var isFirstNameValid: Bool {
        !firstName.isEmpty && !containsBlockedContent(firstName)
    }

    private var isLastNameValid: Bool {
        !lastName.isEmpty && !containsBlockedContent(lastName)
    }

    private var isUsernameValidAndAvailable: Bool {
        usernameStatus == .available && !isCheckingUsername
    }

    private var passwordRequirements: [PasswordRequirement] {
        [
            PasswordRequirement(title: "8+ characters", isMet: password.count >= 8),
            PasswordRequirement(title: "uppercase letter", isMet: password.rangeOfCharacter(from: .uppercaseLetters) != nil),
            PasswordRequirement(title: "lowercase letter", isMet: password.rangeOfCharacter(from: .lowercaseLetters) != nil),
            PasswordRequirement(title: "number", isMet: password.rangeOfCharacter(from: .decimalDigits) != nil),
            PasswordRequirement(title: "special character", isMet: password.rangeOfCharacter(from: CharacterSet.alphanumerics.inverted) != nil),
            PasswordRequirement(title: "does not contain your name or username", isMet: !passwordContainsPersonalInfo)
        ]
    }

    private var isPasswordValid: Bool {
        passwordRequirements.allSatisfy(\.isMet) && !containsBlockedContent(password)
    }

    private var passwordContainsPersonalInfo: Bool {
        let lowercasedPassword = password.lowercased()
        let values = [firstName, lastName, username]
            .map { $0.lowercased() }
            .filter { !$0.isEmpty }

        guard values.allSatisfy({ !lowercasedPassword.contains($0) }) else {
            return true
        }

        guard !username.isEmpty else { return false }
        return levenshteinDistance(lowercasedPassword, username.lowercased()) <= 2
    }

    private var isEmailValid: Bool {
        let parts = email.split(separator: "@", omittingEmptySubsequences: false)
        guard parts.count == 2,
              !parts[0].isEmpty,
              !parts[1].isEmpty,
              parts[1].contains("."),
              !email.contains(" "),
              !containsBlockedContent(email) else {
            return false
        }

        return true
    }

    private func helperText(for field: CreateAccountField) -> String? {
        switch field {
        case .firstName:
            if containsBlockedContent(firstName) { return "Please keep Just Bean It respectful." }
            return attemptedInvalidFirstName ? "letters only" : nil
        case .lastName:
            if containsBlockedContent(lastName) { return "Please keep Just Bean It respectful." }
            return attemptedInvalidLastName ? "letters only" : nil
        case .username:
            guard !username.isEmpty else { return nil }
            if containsBlockedContent(username) { return "Please keep Just Bean It respectful." }
            if username.allSatisfy(\.isNumber) { return "username must include letters" }
            if !isUsernameFormatValid(username) { return "3-20 characters, letters required, only _ or . allowed" }
            if isCheckingUsername { return "checking username" }
            if let usernameAvailabilityReason { return usernameAvailabilityReason }
            return usernameStatus == .available ? "username available" : "username already taken"
        case .password:
            return containsBlockedContent(password) ? "Please keep Just Bean It respectful." : nil
        case .email:
            if containsBlockedContent(email) { return "Please keep Just Bean It respectful." }
            if !email.isEmpty && !isEmailValid { return "enter a valid email" }
            if isSendingCode { return "creating account" }
            return nil
        }
    }

    private func scheduleUsernameCheck() {
        usernameCheckTask?.cancel()
        usernameStatus = nil
        usernameAvailabilityReason = nil
        serviceErrorText = nil

        guard isUsernameFormatValid(username), !containsBlockedContent(username) else {
            isCheckingUsername = false
            usernameStatus = username.isEmpty ? nil : .invalid
            return
        }

        isCheckingUsername = true
        let usernameToCheck = username

        usernameCheckTask = Task {
            try? await Task.sleep(nanoseconds: 500_000_000)
            guard !Task.isCancelled else { return }

            do {
                let response = try await authService.checkUsernameAvailability(username: usernameToCheck)

                await MainActor.run {
                    guard username == usernameToCheck else { return }
                    usernameStatus = response.available ? .available : .unavailable
                    usernameAvailabilityReason = response.reason
                    isCheckingUsername = false
                }
            } catch let error as AuthServiceError {
                await MainActor.run {
                    guard username == usernameToCheck else { return }
                    usernameStatus = .unavailable
                    serviceErrorText = error.localizedDescription
                    isCheckingUsername = false
                }
            } catch {
                print("username check failed:", error)
                await MainActor.run {
                    guard username == usernameToCheck else { return }
                    usernameStatus = .unavailable
                    serviceErrorText = "Something went wrong. Try again."
                    isCheckingUsername = false
                }
            }
        }
    }

    private func back() {
        focusedField = nil
        hideKeyboard()

        if isShowingConfirmation {
            isShowingConfirmation = false
        } else if currentStep == 1 {
            dismiss()
        } else {
            currentStep -= 1
            serviceErrorText = nil
        }
    }

    private func next() {
        guard currentStepIsValid else { return }

        focusedField = nil
        hideKeyboard()
        serviceErrorText = nil

        if currentStep < 5 {
            currentStep += 1
        } else {
            startSignup()
        }
    }

    private var currentStepIsValid: Bool {
        switch currentStep {
        case 1:
            return isFirstNameValid
        case 2:
            return isLastNameValid
        case 3:
            return isUsernameValidAndAvailable
        case 4:
            return isPasswordValid
        default:
            return isEmailValid && hasAcceptedLegal && !isSendingCode
        }
    }

    private func startSignup() {
        guard isEmailValid else {
            serviceErrorText = "Please enter a valid email."
            return
        }

        isSendingCode = true
        serviceErrorText = nil

        Task {
            do {
                try await authService.signUpAndSendVerification(
                    email: email,
                    password: password
                )

                await MainActor.run {
                    isSendingCode = false
                    isShowingConfirmation = true
                    isSignupSuccessful = false
                    startResendCooldown()
                }
            } catch {
                print("signup start failed:", error)
                await MainActor.run {
                    isSendingCode = false
                    if case AuthServiceError.emailAlreadyRegistered = error {
                        routeToLoginForExistingEmail()
                    } else {
                        serviceErrorText = (error as? AuthServiceError)?.localizedDescription ?? "We could not create your account. Try again."
                    }
                }
            }
        }
    }

    private func routeToLoginForExistingEmail() {
        loginEmail = email
        loginMessage = "Looks like you already have an account. Log in instead."
        shouldLoginCompleteSignupProfile = false
        serviceErrorText = nil
        isShowingConfirmation = false
        hideKeyboard()
        isShowingLogin = true
    }

    private var confirmationStepView: some View {
        GeometryReader { geometry in
            ZStack {
                Image("JBIBackground")
                    .resizable()
                    .scaledToFill()
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .clipped()
                    .ignoresSafeArea()

                flowBackButton(in: geometry)

                if isSignupSuccessful {
                    successCard(in: geometry)
                        .position(x: geometry.size.width / 2, y: geometry.size.height * 0.52)
                } else {
                    confirmationCard(in: geometry)
                        .position(x: geometry.size.width / 2, y: geometry.size.height * 0.54)
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .ignoresSafeArea()
        }
        .ignoresSafeArea()
    }

    private func confirmationCard(in geometry: GeometryProxy) -> some View {
        VStack(spacing: 12) {
            Text("CHECK YOUR EMAIL")
                .font(.system(size: 28, weight: .heavy))
                .foregroundStyle(.white)

            Text("We sent a confirmation link to\n\(displayEmail)")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .lineSpacing(2)

            Text("Tap the link in your email.\nThen come back here to finish.")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(.white.opacity(0.9))
                .multilineTextAlignment(.center)
                .frame(width: min(geometry.size.width * 0.82, 320))

            Text(serviceErrorText ?? resendText)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(.white.opacity(0.78))
                .multilineTextAlignment(.center)
                .frame(width: min(geometry.size.width * 0.82, 320))
                .frame(minHeight: 18)

            VStack(spacing: 10) {
                Button {
                    finishAfterEmailConfirmation()
                } label: {
                    Text("I confirmed my email")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 210, height: 38)
                        .background(Color.black.opacity(0.82))
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .disabled(isFinishingConfirmation)
                .opacity(isFinishingConfirmation ? 0.55 : 1)

                Button {
                    resendConfirmationEmail()
                } label: {
                    Text("Resend email")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 160, height: 34)
                        .background(Color.white.opacity(0.18))
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .disabled(resendRemainingSeconds > 0 || isSendingCode)
                .opacity(resendRemainingSeconds > 0 || isSendingCode ? 0.45 : 1)

                Button {
                    routeToLoginAfterConfirmation()
                } label: {
                    Text("Log in instead")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.white.opacity(0.84))
                }
                .buttonStyle(.plain)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 22)
        .padding(.top, 26)
        .frame(width: geometry.size.width * 0.9, height: geometry.size.height * 0.50)
        .confirmationCardStyle()
        .shadow(color: .black.opacity(0.28), radius: 24, x: 0, y: -8)
    }

    private func successCard(in geometry: GeometryProxy) -> some View {
        VStack(spacing: 14) {
            Text("SUCCESSFUL!")
                .font(.system(size: 30, weight: .heavy))
                .foregroundStyle(.white)

            Text(successWelcomeText)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(.white.opacity(0.92))
                .multilineTextAlignment(.center)
                .lineSpacing(2)
                .frame(width: min(geometry.size.width * 0.78, 320))
        }
        .padding(24)
        .frame(width: geometry.size.width * 0.9, height: geometry.size.height * 0.32)
        .confirmationCardStyle()
        .shadow(color: .black.opacity(0.28), radius: 24, x: 0, y: -8)
    }

    private func flowBackButton(in geometry: GeometryProxy) -> some View {
        Button(action: back) {
            Image(systemName: "chevron.left")
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
        .position(x: 34, y: geometry.safeAreaInsets.top + 72)
    }

    private var displayEmail: String {
        email.isEmpty ? "your email" : email
    }

    private var resendText: String {
        resendRemainingSeconds > 0 ? "Resend available in \(resendRemainingSeconds)s" : " "
    }

    private func resendConfirmationEmail() {
        guard resendRemainingSeconds == 0 else { return }

        isSendingCode = true
        serviceErrorText = nil

        Task {
            do {
                try await authService.resendConfirmation(email: email)
                await MainActor.run {
                    isSendingCode = false
                    serviceErrorText = "Confirmation email sent."
                    startResendCooldown()
                }
            } catch {
                print("resend confirmation email failed:", error)
                await MainActor.run {
                    isSendingCode = false
                    serviceErrorText = "We could not resend the email. Try again."
                }
            }
        }
    }

    private func startResendCooldown() {
        resendTask?.cancel()
        resendRemainingSeconds = 30

        resendTask = Task {
            while !Task.isCancelled, resendRemainingSeconds > 0 {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                await MainActor.run {
                    if resendRemainingSeconds > 0 {
                        resendRemainingSeconds -= 1
                    }
                }
            }
        }
    }

    private func finishAfterEmailConfirmation() {
        hideKeyboard()
        serviceErrorText = nil
        isFinishingConfirmation = true

        Task {
            do {
                try await authService.signIn(email: email, password: password)

                try await authService.completeProfileForCurrentSession(
                    firstName: firstName,
                    lastName: lastName,
                    username: username,
                    email: email
                )

                await MainActor.run {
                    isFinishingConfirmation = false
                    isSignupSuccessful = true
                }

                try? await Task.sleep(nanoseconds: 1_150_000_000)

                await MainActor.run {
                    guard isSignupSuccessful else { return }
                    onAuthenticated()
                    dismiss()
                }
            } catch AuthServiceError.emailNotConfirmed {
                await MainActor.run {
                    isFinishingConfirmation = false
                    serviceErrorText = "Confirm your email first, then tap this again."
                }
            } catch let error as AuthServiceError {
                print("finish confirmation failed:", error)
                await MainActor.run {
                    isFinishingConfirmation = false
                    if case .usernameUnavailable = error {
                        serviceErrorText = error.localizedDescription
                    } else {
                        serviceErrorText = "We could not finish setup. Try logging in."
                    }
                }
            } catch {
                print("finish confirmation failed:", error)
                await MainActor.run {
                    isFinishingConfirmation = false
                    serviceErrorText = "We could not finish setup. Try logging in."
                }
            }
        }
    }

    private func routeToLoginAfterConfirmation() {
        loginEmail = email
        loginMessage = "Log in after confirming your email."
        shouldLoginCompleteSignupProfile = true
        serviceErrorText = nil
        isShowingConfirmation = false
        hideKeyboard()
        isShowingLogin = true
    }

    private var successWelcomeText: String {
        let initial = lastName.first.map { "\(String($0).uppercased())." } ?? ""
        return "Welcome \(firstName) \(initial) | @\(username)"
    }

    private func lettersOnly(_ text: String) -> String {
        String(text.trimmingCharacters(in: .whitespacesAndNewlines).filter { character in
            character.isLetter && character.isASCII
        })
    }

    private func isUsernameFormatValid(_ username: String) -> Bool {
        guard username.count >= 3,
              username.count <= 20,
              username.allSatisfy(\.isASCII),
              username.contains(where: { $0.isLetter }),
              !username.allSatisfy(\.isNumber),
              let first = username.first,
              let last = username.last,
              first != "." && first != "_",
              last != "." && last != "_" else {
            return false
        }

        let allowedCharacters = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyz0123456789._")
        guard username.unicodeScalars.allSatisfy({ allowedCharacters.contains($0) }) else {
            return false
        }

        return !username.contains("..") &&
            !username.contains("__") &&
            !username.contains("._") &&
            !username.contains("_.")
    }

    private func containsBlockedContent(_ text: String) -> Bool {
        let blockedWords = ["badword", "hate", "slur", "abuse"]
        let normalized = text.lowercased()
        return blockedWords.contains { normalized.contains($0) }
    }

    private func levenshteinDistance(_ lhs: String, _ rhs: String) -> Int {
        let lhs = Array(lhs)
        let rhs = Array(rhs)
        var distances = Array(0...rhs.count)

        for (lhsIndex, lhsCharacter) in lhs.enumerated() {
            var previous = distances[0]
            distances[0] = lhsIndex + 1

            for (rhsIndex, rhsCharacter) in rhs.enumerated() {
                let current = distances[rhsIndex + 1]
                distances[rhsIndex + 1] = lhsCharacter == rhsCharacter
                    ? previous
                    : min(previous, distances[rhsIndex], distances[rhsIndex + 1]) + 1
                previous = current
            }
        }

        return distances[rhs.count]
    }
}

private extension View {
    func confirmationCardStyle() -> some View {
        self
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
    }
}

#Preview {
    NavigationStack {
        CreateAccountFlowView {}
    }
}
