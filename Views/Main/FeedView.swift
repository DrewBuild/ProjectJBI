import SwiftUI

struct FeedView: View {
    let displayName: String
    let onSignedOut: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    @State private var posts: [FeedPost] = []
    @State private var isLoading = true
    @State private var errorText: String?
    @State private var showNotifications = false
    @State private var showFriendSearch = false
    @State private var showMenu = false
    @State private var isSigningOut = false
    @State private var navigationPath: [UUID] = []
    @AppStorage("appColorScheme") private var appColorScheme = "system"

    private let postService = PostService()

    private var foregroundColor: Color {
        colorScheme == .dark ? .white : .black
    }

    var body: some View {
        NavigationStack(path: $navigationPath) {
            GeometryReader { geometry in
                let headerHeight = geometry.safeAreaInsets.top + 42

                ZStack(alignment: .top) {
                    AppScreenBackground()

                    ScrollView {
                        VStack(spacing: 14) {
                            Color.clear
                                .frame(height: headerHeight + 16)

                            if isLoading {
                                ProgressView()
                                    .tint(foregroundColor)
                                    .padding(.top, 80)
                            } else if posts.isEmpty {
                                emptyState
                                    .padding(.top, 82)
                            } else {
                                ForEach(posts) { post in
                                    FeedPostCardView(feedPost: post)
                                }
                            }

                            if let errorText {
                                Text(errorText)
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundStyle(.red.opacity(0.9))
                                    .multilineTextAlignment(.center)
                                    .padding(.top, 8)
                            }

                            Spacer(minLength: 100)
                        }
                        .padding(.horizontal, 16)
                    }
                    .scrollContentBackground(.hidden)
                    .refreshable {
                        await loadFeed()
                    }

                    MainHeaderView(
                        displayName: displayName,
                        section: "feed",
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
                .task {
                    await loadFeed()
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    private var emptyState: some View {
        Text("No posts yet.\nFollow friends or create your first coffee post.")
            .font(.system(size: 15, weight: .bold))
            .foregroundStyle(foregroundColor.opacity(0.62))
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
    }

    private func loadFeed() async {
        do {
            posts = try await postService.fetchFeedPosts()
            errorText = nil
        } catch {
            print("FeedView load failed:", error)
            errorText = "Could not load posts. Try again."
        }
        isLoading = false
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
                print("FeedView signOut failed:", error)
                await MainActor.run {
                    isSigningOut = false
                    showMenu = false
                    errorText = "Could not log out. Try again."
                }
            }
        }
    }
}

#Preview {
    FeedView(displayName: "Drew J.", onSignedOut: {})
}
