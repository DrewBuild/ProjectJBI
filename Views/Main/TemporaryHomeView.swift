import SwiftUI

struct TemporaryHomeView: View {
    let onSignedOut: () -> Void

    @State private var isSigningOut = false
    @State private var errorText: String?

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Image("JBIBackground")
                    .resizable()
                    .scaledToFill()
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .clipped()
                    .ignoresSafeArea()

                VStack(spacing: 18) {
                    Text("Welcome to Just Bean It.")
                        .font(.system(size: 32, weight: .heavy))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)

                    Text("Your account is ready.")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white.opacity(0.88))

                    if let errorText {
                        Text(errorText)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(.white.opacity(0.78))
                            .multilineTextAlignment(.center)
                    }

                    Button {
                        signOut()
                    } label: {
                        Text(isSigningOut ? "Signing out..." : "Sign out")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.black.opacity(0.82))
                            .frame(width: 150, height: 42)
                            .background(Color.white.opacity(0.88))
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .disabled(isSigningOut)
                    .opacity(isSigningOut ? 0.6 : 1)
                }
                .padding(.horizontal, 28)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .ignoresSafeArea()
        }
        .ignoresSafeArea()
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
