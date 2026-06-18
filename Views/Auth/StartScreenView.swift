import SwiftUI
import UIKit

struct StartScreenView: View {
    var onAuthenticated: () -> Void = {}

    @Environment(\.colorScheme) private var colorScheme

    private var characterAssetName: String {
        colorScheme == .dark ? "JBICharacterL" : "JBICharacterD"
    }

    private var foregroundColor: Color {
        colorScheme == .dark ? .white : .black
    }

    private var primaryButtonFill: Color {
        Color.jbiAccent(for: colorScheme)
    }

    private var primaryButtonText: Color {
        colorScheme == .dark ? JBITheme.darkBlue : .white
    }
    private let phrases = [
        "Rate every cup.",
        "Share your favorite coffee spots.",
        "Find what your friends love."
    ]

    @State private var displayedText = ""
    @State private var typingTask: Task<Void, Never>?
    @State private var isShowingCreateFlow = false
    @State private var isShowingLogin = false
    @State private var legalDocument: LegalDocument?
    @State private var isStartScreenVisible = false

    var body: some View {
        NavigationStack {
            ZStack {
                GeometryReader { geometry in
                    ZStack {
                        SolidAppBackground()

                        headlineSection(in: geometry)
                            .position(
                                x: geometry.size.width / 2,
                                y: geometry.size.height * headlineYRatio(for: geometry.size.height)
                            )

                        Image(characterAssetName)
                            .resizable()
                            .scaledToFit()
                            .frame(width: characterWidth(for: geometry.size.width))
                            .position(
                                x: min(geometry.size.width * 0.70, geometry.size.width - 98),
                                y: geometry.size.height * characterYRatio(for: geometry.size.height)
                            )
                            .accessibilityHidden(true)

                        Text(displayedText.isEmpty ? " " : displayedText)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(foregroundColor)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                            .frame(width: min(geometry.size.width - 56, 320), height: 44)
                            .position(x: geometry.size.width / 2, y: geometry.size.height * 0.565)

                        buttons
                            .position(x: geometry.size.width / 2, y: geometry.size.height * buttonStackYRatio(for: geometry.size.height))

                        Text("By continuing, you agree to our\nTerms of Service and Privacy Policy")
                            .hidden()
                            .position(
                                x: geometry.size.width / 2,
                                y: min(geometry.size.height * 0.952, geometry.size.height - geometry.safeAreaInsets.bottom - 18)
                            )

                        footerLegalText
                            .position(
                                x: geometry.size.width / 2,
                                y: min(geometry.size.height * 0.952, geometry.size.height - geometry.safeAreaInsets.bottom - 18)
                            )
                    }
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .ignoresSafeArea()
                }

                if let legalDocument {
                    LegalPopupView(document: legalDocument) {
                        self.legalDocument = nil
                    }
                    .zIndex(2)
                }

                if isShowingLogin {
                    LoginView(onAuthenticated: onAuthenticated) {
                        closeLogin()
                    }
                    .transition(.asymmetric(insertion: .move(edge: .leading), removal: .move(edge: .leading)))
                    .zIndex(3)
                }
            }
            .ignoresSafeArea()
            .navigationBarBackButtonHidden(true)
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(isPresented: $isShowingCreateFlow) {
                CreateAccountFlowView(onAuthenticated: onAuthenticated)
            }
        }
        .ignoresSafeArea()
        .onAppear {
            startTypingAnimation()
        }
        .onDisappear {
            stopTypingAnimation()
        }
        .onChange(of: isShowingCreateFlow) { _, isShowing in
            if isShowing {
                stopTypingAnimation()
            } else {
                startTypingAnimation()
            }
        }
    }

    private func headlineSection(in geometry: GeometryProxy) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("JUST BEAN IT.")
                .font(.system(size: titleSize(for: geometry.size.width), weight: .heavy))
                .foregroundStyle(foregroundColor)
                .lineSpacing(0)
                .minimumScaleFactor(0.9)
                .lineLimit(1)

            Text("FIRST EVER COFFEE SOCIAL\nMEDIA APP.")
                .font(.system(size: subtitleSize(for: geometry.size.width), weight: .heavy))
                .foregroundStyle(foregroundColor.opacity(0.9))
                .lineSpacing(0)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(width: geometry.size.width - 56, alignment: .leading)
    }

    private var buttons: some View {
        VStack(spacing: 9) {
            Button {
                stopTypingAnimation()
                isShowingCreateFlow = true
            } label: {
                Text("CREATE")
                    .font(.system(size: 20, weight: .heavy))
                    .foregroundStyle(primaryButtonText)
                    .frame(width: 250, height: 56)
                    .background(primaryButtonFill)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)

            Text("or")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(foregroundColor)

            Button {
                openLogin()
            } label: {
                Text("LOG IN")
                    .font(.system(size: 20, weight: .heavy))
                    .foregroundStyle(primaryButtonText)
                    .frame(width: 250, height: 56)
                    .background(primaryButtonFill)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
    }

    private var footerLegalText: some View {
        VStack(spacing: 0) {
            Text("By continuing, you agree to our")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(foregroundColor.opacity(0.76))

            HStack(spacing: 3) {
                Button {
                    legalDocument = .terms
                } label: {
                    Text("Terms of Service")
                        .underline()
                }

                Text("and")

                Button {
                    legalDocument = .privacy
                } label: {
                    Text("Privacy Policy")
                        .underline()
                }
            }
            .font(.system(size: 11, weight: .bold))
            .foregroundStyle(foregroundColor.opacity(0.76))
            .buttonStyle(.plain)
        }
        .multilineTextAlignment(.center)
    }

    private func titleSize(for width: CGFloat) -> CGFloat {
        width <= 340 ? 28 : 30
    }

    private func subtitleSize(for width: CGFloat) -> CGFloat {
        width <= 340 ? 12 : 13
    }

    private func characterWidth(for width: CGFloat) -> CGFloat {
        min(max(width * 0.47, 180), 195)
    }

    private func headlineYRatio(for height: CGFloat) -> CGFloat {
        height <= 700 ? 0.285 : 0.275
    }

    private func characterYRatio(for height: CGFloat) -> CGFloat {
        height <= 700 ? 0.415 : 0.402
    }

    private func buttonStackYRatio(for height: CGFloat) -> CGFloat {
        height <= 700 ? 0.742 : 0.725
    }

    private func startTypingAnimation() {
        typingTask?.cancel()
        typingTask = nil
        displayedText = ""
        isStartScreenVisible = true

        typingTask = Task { @MainActor in
            let haptic = UIImpactFeedbackGenerator(style: .light)
            haptic.prepare()
            var phraseIndex = 0
            var characterIndex = 0
            var isDeleting = false

            while !Task.isCancelled && isStartScreenVisible {
                let phrase = phrases[phraseIndex]

                if isDeleting {
                    if characterIndex > 0 {
                        characterIndex -= 1
                        guard isStartScreenVisible && !Task.isCancelled else { return }
                        displayedText = String(phrase.prefix(characterIndex))
                        try? await Task.sleep(nanoseconds: 45_000_000)
                    } else {
                        isDeleting = false
                        phraseIndex = (phraseIndex + 1) % phrases.count
                        try? await Task.sleep(nanoseconds: 220_000_000)
                    }
                } else {
                    if characterIndex < phrase.count {
                        characterIndex += 1
                        guard isStartScreenVisible && !Task.isCancelled else { return }
                        displayedText = String(phrase.prefix(characterIndex))
                        guard isStartScreenVisible && !Task.isCancelled else { return }
                        haptic.impactOccurred(intensity: 0.45)
                        haptic.prepare()
                        try? await Task.sleep(nanoseconds: 75_000_000)
                    } else {
                        try? await Task.sleep(nanoseconds: 1_250_000_000)
                        isDeleting = true
                    }
                }
            }
        }
    }

    private func stopTypingAnimation() {
        isStartScreenVisible = false
        typingTask?.cancel()
        typingTask = nil
    }

    private func openLogin() {
        stopTypingAnimation()
        withAnimation(.spring(response: 0.34, dampingFraction: 0.9)) {
            isShowingLogin = true
        }
    }

    private func closeLogin() {
        withAnimation(.spring(response: 0.34, dampingFraction: 0.9)) {
            isShowingLogin = false
        }
        isStartScreenVisible = true
        startTypingAnimation()
    }
}

#Preview {
    StartScreenView()
}
