import SwiftUI
import UIKit

enum CreateAccountField: Hashable {
    case firstName
    case lastName
    case username
    case password
    case email
}

enum UsernameStatus {
    case available
    case unavailable
    case invalid
}

struct PasswordRequirement: Identifiable {
    let id = UUID()
    let title: String
    let isMet: Bool
}

struct CreateStepView: View {
    let step: Int
    let title: String
    let subtitle: String
    let placeholder: String
    let previewText: String
    let field: CreateAccountField
    let helperText: String?
    let serviceErrorText: String?
    let usernameStatus: UsernameStatus?
    let isCheckingUsername: Bool
    let passwordRequirements: [PasswordRequirement]
    let showsCreationLegalText: Bool
    let showsAgreementCheckbox: Bool
    let isNextEnabled: Bool
    let onBack: () -> Void
    let onNext: () -> Void
    let onShowTerms: () -> Void
    let onShowPrivacy: () -> Void

    @Binding var text: String
    @Binding var isPasswordVisible: Bool
    @Binding var hasAcceptedLegal: Bool
    let focusedField: FocusState<CreateAccountField?>.Binding

    @State private var typedTitle = ""
    @State private var titleAnimationTask: Task<Void, Never>?

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Image("JBIBackground")
                    .resizable()
                    .scaledToFill()
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .clipped()
                    .ignoresSafeArea()

                topControls(in: geometry)

                formContent(in: geometry)
                    .position(x: geometry.size.width / 2, y: geometry.size.height * contentYRatio(for: geometry.size.height))

                if field == .password {
                    passwordChecklist
                        .frame(width: min(geometry.size.width * 0.78, 310), alignment: .leading)
                        .position(x: geometry.size.width / 2, y: geometry.size.height * passwordChecklistYRatio(for: geometry.size.height))
                }

                Text(previewText)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .frame(width: geometry.size.width - 56)
                    .position(
                        x: geometry.size.width / 2,
                        y: min(geometry.size.height * 0.918, geometry.size.height - geometry.safeAreaInsets.bottom - 46)
                    )

                if showsCreationLegalText {
                    creationLegalText
                        .frame(width: geometry.size.width - 56)
                        .position(
                            x: geometry.size.width / 2,
                            y: min(geometry.size.height * 0.89, geometry.size.height - geometry.safeAreaInsets.bottom - 76)
                        )
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .contentShape(Rectangle())
            .onTapGesture {
                focusedField.wrappedValue = nil
                hideKeyboard()
            }
        }
        .ignoresSafeArea()
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .onAppear(perform: startTitleAnimation)
        .onChange(of: title) { _, _ in
            startTitleAnimation()
        }
        .onDisappear {
            titleAnimationTask?.cancel()
            titleAnimationTask = nil
        }
    }

    private func topControls(in geometry: GeometryProxy) -> some View {
        Button(action: onBack) {
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

    private func formContent(in geometry: GeometryProxy) -> some View {
        VStack(spacing: 12) {
            Text(typedTitle.isEmpty ? " " : typedTitle)
                .font(.system(size: titleSize, weight: .heavy))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .lineSpacing(1)
                .textCase(.uppercase)
                .frame(minHeight: titleHeight)

            Text(subtitle)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)

            inputField(width: min(geometry.size.width * 0.80, 310))

            Text(helperText ?? " ")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(.white.opacity(0.72))
                .multilineTextAlignment(.center)
                .frame(height: 16)

            if showsAgreementCheckbox {
                agreementRow
                    .padding(.top, 1)
            }

            Text(serviceErrorText ?? " ")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(.white.opacity(0.8))
                .multilineTextAlignment(.center)
                .frame(width: min(geometry.size.width * 0.82, 320), height: 18)

            Button(action: onNext) {
                Text("next")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.black.opacity(0.82))
                    .frame(width: 138, height: 38)
                    .background(Color.white.opacity(0.88))
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .disabled(!isNextEnabled)
            .opacity(isNextEnabled ? 1 : 0.45)
            .padding(.top, 1)

            Text("\(step)/5")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private func inputField(width: CGFloat) -> some View {
        ZStack(alignment: .trailing) {
            fieldBackground(width: width)

            if field == .password {
                passwordInput(width: width)
            } else {
                TextField("", text: $text, prompt: Text(placeholder).foregroundStyle(.black.opacity(0.45)))
                    .keyboardType(keyboardType)
                    .textInputAutocapitalization(textCapitalization)
                    .autocorrectionDisabled(autocorrectionDisabled)
                    .focused(focusedField, equals: field)
                    .inputTextStyle()
                    .padding(.horizontal, trailingPadding)
                    .frame(width: width, height: 44)
            }

            if field == .username {
                Text("@")
                    .font(.system(size: 17, weight: .heavy))
                    .foregroundStyle(.black.opacity(0.62))
                    .frame(width: 24, height: 44)
                    .position(x: 27, y: 22)
            }

            trailingIcon
                .padding(.trailing, 13)
        }
        .frame(width: width, height: 44)
    }

    private func fieldBackground(width: CGFloat) -> some View {
        Capsule()
            .fill(Color(red: 0.94, green: 0.73, blue: 0.72))
            .frame(width: width, height: 44)
    }

    @ViewBuilder
    private func passwordInput(width: CGFloat) -> some View {
        if isPasswordVisible {
            TextField("", text: $text, prompt: Text(placeholder).foregroundStyle(.black.opacity(0.45)))
                .textContentType(.newPassword)
                .focused(focusedField, equals: field)
                .inputTextStyle()
                .padding(.leading, 24)
                .padding(.trailing, 52)
                .frame(width: width, height: 44)
        } else {
            SecureField("", text: $text, prompt: Text(placeholder).foregroundStyle(.black.opacity(0.45)))
                .textContentType(.newPassword)
                .focused(focusedField, equals: field)
                .inputTextStyle()
                .padding(.leading, 24)
                .padding(.trailing, 52)
                .frame(width: width, height: 44)
        }
    }

    @ViewBuilder
    private var trailingIcon: some View {
        if field == .username, isCheckingUsername, !text.isEmpty {
            ProgressView()
                .scaleEffect(0.72)
                .tint(.black.opacity(0.7))
        } else if field == .username, let usernameStatus, !text.isEmpty {
            Image(systemName: usernameStatus == .available ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(usernameStatus == .available ? .green : .red)
        } else if field == .password {
            Button {
                isPasswordVisible.toggle()
            } label: {
                Image(systemName: isPasswordVisible ? "eye.slash.fill" : "eye.fill")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(.black.opacity(0.62))
            }
            .buttonStyle(.plain)
        }
    }

    private var agreementRow: some View {
        HStack(alignment: .center, spacing: 8) {
            Button {
                hasAcceptedLegal.toggle()
            } label: {
                Image(systemName: hasAcceptedLegal ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(hasAcceptedLegal ? .green : .white.opacity(0.78))
            }
            .buttonStyle(.plain)

            HStack(spacing: 3) {
                Text("I agree to the")

                Button("Terms of Service", action: onShowTerms)
                    .underline()

                Text("and")

                Button("Privacy Policy", action: onShowPrivacy)
                    .underline()
            }
            .font(.system(size: 11, weight: .bold))
            .foregroundStyle(.white.opacity(0.78))
            .buttonStyle(.plain)
        }
        .frame(maxWidth: 320)
    }

    private var passwordChecklist: some View {
        VStack(alignment: .leading, spacing: 5) {
            ForEach(passwordRequirements) { requirement in
                HStack(spacing: 7) {
                    Image(systemName: requirement.isMet ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(requirement.isMet ? .green : .red)

                    Text(requirement.title)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white.opacity(0.72))
                }
            }
        }
    }

    private var titleSize: CGFloat {
        title.count > 24 ? 30 : 34
    }

    private var titleHeight: CGFloat {
        title.contains("\n") ? 92 : 44
    }

    private var trailingPadding: CGFloat {
        field == .username ? 48 : 24
    }

    private func contentYRatio(for height: CGFloat) -> CGFloat {
        height <= 700 ? 0.45 : 0.385
    }

    private func passwordChecklistYRatio(for height: CGFloat) -> CGFloat {
        height <= 700 ? 0.72 : 0.70
    }

    private var keyboardType: UIKeyboardType {
        field == .email ? .emailAddress : .default
    }

    private var textCapitalization: TextInputAutocapitalization {
        switch field {
        case .username, .email:
            return .never
        default:
            return .words
        }
    }

    private var autocorrectionDisabled: Bool {
        field == .username || field == .email
    }

    private func startTitleAnimation() {
        titleAnimationTask?.cancel()
        typedTitle = ""

        titleAnimationTask = Task { @MainActor in
            let haptic = UIImpactFeedbackGenerator(style: .light)
            haptic.prepare()

            for character in title {
                guard !Task.isCancelled else { return }
                typedTitle.append(character)
                haptic.impactOccurred(intensity: 0.45)
                haptic.prepare()
                try? await Task.sleep(nanoseconds: 45_000_000)
            }
        }
    }
}

extension CreateStepView {
    var creationLegalText: some View {
        VStack(spacing: 2) {
            Text("By creating an account, you agree to our")

            HStack(spacing: 3) {
                Button("Terms of Service", action: onShowTerms).underline()
                Text("and")
                Button("Privacy Policy", action: onShowPrivacy).underline()
            }
        }
        .font(.system(size: 11, weight: .bold))
        .foregroundStyle(.white.opacity(0.72))
        .buttonStyle(.plain)
        .multilineTextAlignment(.center)
    }
}

private extension View {
    func inputTextStyle() -> some View {
        self
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(.black.opacity(0.82))
            .multilineTextAlignment(.center)
            .textFieldStyle(.plain)
    }
}

func hideKeyboard() {
    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
}
