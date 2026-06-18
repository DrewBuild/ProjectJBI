import SwiftUI

struct ProfileView: View {
    let displayName: String
    @Binding var isTabBarMinimized: Bool
    let onSignedOut: () -> Void

    @State private var lastOffset: CGFloat = 0
    @State private var isSigningOut = false
    @State private var errorText: String?

    private let hotPink = Color(red: 1.0, green: 0.12, blue: 0.72)

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                AppScreenBackground()

                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(spacing: 24) {
                            Color.clear
                                .frame(height: 0)
                                .id("top")

                            MainHeaderView(displayName: displayName, section: "profile")
                                .padding(.top, geometry.safeAreaInsets.top + 34)

                            Spacer(minLength: 160)

                            if let errorText {
                                Text(errorText)
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundStyle(.red.opacity(0.85))
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 28)
                            }

                            Button {
                                logOut()
                            } label: {
                                Text(isSigningOut ? "Logging out..." : "Log Out")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundStyle(.white)
                                    .frame(width: 200, height: 48)
                                    .background(hotPink)
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                            .disabled(isSigningOut)
                            .opacity(isSigningOut ? 0.6 : 1)

                            Spacer(minLength: 800)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .scrollContentBackground(.hidden)
                    .onScrollGeometryChange(for: CGFloat.self) { geo in
                        geo.contentOffset.y
                    } action: { _, newOffset in
                        updateMinimized(newOffset: newOffset)
                    }
                    .onReceive(NotificationCenter.default.publisher(for: .jbiRevealTabBar)) { _ in
                        withAnimation(.easeInOut(duration: 0.25)) {
                            proxy.scrollTo("top", anchor: .top)
                        }
                        if isTabBarMinimized { isTabBarMinimized = false }
                    }
                }
            }
            .ignoresSafeArea()
        }
    }

    private func updateMinimized(newOffset: CGFloat) {
        let delta = newOffset - lastOffset
        if delta > 8, !isTabBarMinimized {
            isTabBarMinimized = true
        } else if (delta < -8 || newOffset < 8), isTabBarMinimized {
            isTabBarMinimized = false
        }
        lastOffset = newOffset
    }

    private func logOut() {
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
                print("ProfileView signOut failed:", error)
                await MainActor.run {
                    isSigningOut = false
                    errorText = "Could not log out. Try again."
                }
            }
        }
    }
}

#Preview {
    ProfileView(displayName: "Drew J.", isTabBarMinimized: .constant(false), onSignedOut: {})
}
