import SwiftUI

struct TemporaryHomeView: View {
    let onSignedOut: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    @State private var isSigningOut = false
    @State private var errorText: String?

    private var foregroundColor: Color {
        colorScheme == .dark ? .white : .black
    }

    private var buttonFill: Color {
        colorScheme == .dark ? .white : .black
    }

    private var buttonText: Color {
        colorScheme == .dark ? .black : .white
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                AppScreenBackground()

                VStack(spacing: 18) {
                    Text("Welcome to Just Bean It.")
                        .font(.system(size: 32, weight: .heavy))
                        .foregroundStyle(foregroundColor)
                        .multilineTextAlignment(.center)

                    Text("Your account is ready.")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(foregroundColor.opacity(0.78))

                    if let errorText {
                        Text(errorText)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(foregroundColor.opacity(0.78))
                            .multilineTextAlignment(.center)
                    }

                    Button {
                        signOut()
                    } label: {
                        Text(isSigningOut ? "Signing out..." : "Sign out")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(buttonText)
                            .frame(width: 150, height: 42)
                            .background(buttonFill)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .disabled(isSigningOut)
                    .opacity(isSigningOut ? 0.6 : 1)
                }
                .padding(.horizontal, 28)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
    }

    private func signOut() {
        isSigningOut = true
        errorText = nil

        Task {
            do {
                try await AuthService().signOut()
                await MainActor.run {
                    isSigningOut = false
                    onSignedOut()
                }
            } catch {
                print("signOut failed:", error)
                await MainActor.run {
                    isSigningOut = false
                    errorText = "Something went wrong. Try again."
                }
            }
        }
    }
}

#Preview {
    TemporaryHomeView {}
}
