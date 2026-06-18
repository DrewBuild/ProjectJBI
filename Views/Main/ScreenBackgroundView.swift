import SwiftUI

struct SolidAppBackground: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        (colorScheme == .dark ? Color.black : Color.white)
            .ignoresSafeArea()
    }
}

struct AppScreenBackground: View {
    var body: some View {
        SolidAppBackground()
    }
}

struct MainHeaderView: View {
    let displayName: String
    let section: String
    let onNotifications: () -> Void
    let onFindFriends: () -> Void
    let onMenu: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    private var foregroundColor: Color {
        colorScheme == .dark ? .white : .black
    }

    private var backgroundColor: Color {
        colorScheme == .dark ? Color.black.opacity(0.72) : Color.white.opacity(0.72)
    }

    private var dividerColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.10) : Color.black.opacity(0.08)
    }

    var body: some View {
        GeometryReader { geometry in
            let safeTop = geometry.safeAreaInsets.top

            ZStack(alignment: .bottom) {
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .overlay(backgroundColor)
                    .ignoresSafeArea(edges: .top)

                Rectangle()
                    .fill(dividerColor)
                    .frame(height: 1)

                ZStack {
                    Text("\(displayName) | \(section)")
                        .font(.system(size: 13, weight: .heavy))
                        .foregroundStyle(foregroundColor)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.horizontal, 72)

                    HStack(spacing: 2) {
                        Button(action: onNotifications) {
                            Image(systemName: "bell.fill")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundStyle(foregroundColor)
                                .frame(width: 44, height: 44)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Notifications")

                        Button(action: onFindFriends) {
                            Image(systemName: "person.2.badge.plus.fill")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundStyle(foregroundColor)
                                .frame(width: 44, height: 44)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Find friends")

                        Spacer()

                        Button(action: onMenu) {
                            Image(systemName: "line.3.horizontal")
                                .font(.system(size: 21, weight: .bold))
                                .foregroundStyle(foregroundColor)
                                .frame(width: 44, height: 44)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Main menu")
                    }
                    .padding(.horizontal, 18)
                }
                .padding(.top, safeTop + 4)
                .frame(height: safeTop + 42, alignment: .top)
            }
        }
    }
}

struct MainMenuOverlay: View {
    let isSigningOut: Bool
    let onToggleAppearance: () -> Void
    let onSignOut: () -> Void
    let onDismiss: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("useLocationForPosts") private var useLocationForPosts = true

    private var textColor: Color {
        colorScheme == .dark ? .white : .black
    }

    private var borderColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.24) : Color.black.opacity(0.14)
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .topTrailing) {
                Color.black.opacity(0.001)
                    .ignoresSafeArea()
                    .onTapGesture(perform: onDismiss)

                VStack(alignment: .leading, spacing: 0) {
                    Button(action: onToggleAppearance) {
                        row(icon: "circle.lefthalf.filled", title: "Toggle Light/Dark Mode")
                    }
                    .buttonStyle(.plain)

                    Divider()
                        .background(borderColor)

                    Button {
                        useLocationForPosts.toggle()
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: useLocationForPosts ? "location.fill" : "location.slash.fill")
                                .font(.system(size: 16, weight: .bold))
                                .frame(width: 22)
                            Text("Use location for posts")
                                .font(.system(size: 14, weight: .bold))
                            Spacer()
                            Image(systemName: useLocationForPosts ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 16, weight: .bold))
                        }
                        .foregroundStyle(textColor)
                        .padding(.horizontal, 16)
                        .frame(height: 52)
                    }
                    .buttonStyle(.plain)

                    Divider()
                        .background(borderColor)

                    Button(action: onSignOut) {
                        row(icon: "rectangle.portrait.and.arrow.right", title: isSigningOut ? "Logging Out" : "Log Out")
                    }
                    .buttonStyle(.plain)
                    .disabled(isSigningOut)
                }
                .frame(width: min(292, geometry.size.width - 42))
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(borderColor, lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.26), radius: 18, x: 0, y: 10)
                .padding(.top, geometry.safeAreaInsets.top + 62)
                .padding(.trailing, 18)
            }
        }
    }

    private func row(icon: String, title: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .bold))
                .frame(width: 22)
            Text(title)
                .font(.system(size: 14, weight: .bold))
            Spacer()
        }
        .foregroundStyle(textColor)
        .padding(.horizontal, 16)
        .frame(height: 52)
    }
}

struct LoggedInPageView: View {
    let displayName: String
    let section: String
    let onSignedOut: () -> Void

    @State private var showNotifications = false
    @State private var showFriendSearch = false
    @State private var showMenu = false
    @State private var isSigningOut = false
    @State private var errorText: String?
    @State private var navigationPath: [UUID] = []
    @AppStorage("appColorScheme") private var appColorScheme = "system"

    var body: some View {
        NavigationStack(path: $navigationPath) {
            GeometryReader { geometry in
                let headerHeight = geometry.safeAreaInsets.top + 42

                ZStack(alignment: .top) {
                    AppScreenBackground()

                    ScrollView {
                        VStack(spacing: 0) {
                            Color.clear
                                .frame(height: headerHeight + 16)

                            if let errorText {
                                Text(errorText)
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundStyle(.red.opacity(0.9))
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 24)
                            }

                            Spacer(minLength: 1200)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .scrollContentBackground(.hidden)
                    .refreshable {
                        await refresh()
                    }

                    MainHeaderView(
                        displayName: displayName,
                        section: section,
                        onNotifications: { showNotifications = true },
                        onFindFriends: { showFriendSearch = true },
                        onMenu: { withAnimation(.easeInOut(duration: 0.18)) { showMenu.toggle() } }
                    )
                    .frame(height: headerHeight)
                    .zIndex(1)

                    if showMenu {
                        MainMenuOverlay(
                            isSigningOut: isSigningOut,
                            onToggleAppearance: toggleAppearance,
                            onSignOut: signOut,
                            onDismiss: { withAnimation(.easeInOut(duration: 0.18)) { showMenu = false } }
                        )
                        .zIndex(2)
                    }
                }
                .sheet(isPresented: $showNotifications) {
                    NotificationView(displayName: displayName)
                }
                .sheet(isPresented: $showFriendSearch) {
                    FriendSearchView { selected in
                        navigationPath.append(selected.id)
                    }
                }
                .navigationDestination(for: UUID.self) { id in
                    ProfileView(profileId: id, onSignedOut: onSignedOut, ownsNavigationStack: false)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    private func toggleAppearance() {
        appColorScheme = appColorScheme == "dark" ? "light" : "dark"
        withAnimation(.easeInOut(duration: 0.18)) {
            showMenu = false
        }
    }

    private func signOut() {
        guard !isSigningOut else { return }
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
                print("LoggedInPageView signOut failed:", error)
                await MainActor.run {
                    isSigningOut = false
                    showMenu = false
                    errorText = "Could not log out. Try again."
                }
            }
        }
    }

    private func refresh() async {}
}

#Preview {
    LoggedInPageView(displayName: "Drew J.", section: "feed", onSignedOut: {})
}
