import SwiftUI

struct ProfileView: View {
    let profileId: UUID?
    let onSignedOut: () -> Void
    let ownsNavigationStack: Bool

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    @State private var profile: UserProfile?
    @State private var counts = FollowCounts()
    @State private var relationship: ProfileRelationship = .notFollowing
    @State private var isLoading = true
    @State private var isUpdatingRelationship = false
    @State private var isSigningOut = false
    @State private var errorText: String?
    @State private var showMenu = false
    @State private var showNotifications = false
    @State private var showFriendSearch = false
    @State private var showFollowers = false
    @State private var showFollowing = false
    @State private var showEditProfile = false
    @State private var navigationPath: [UUID] = []
    @AppStorage("appColorScheme") private var appColorScheme = "system"

    private let service = ProfileService()

    private var foregroundColor: Color {
        colorScheme == .dark ? .white : .black
    }

    private var secondaryColor: Color {
        foregroundColor.opacity(0.7)
    }

    private var buttonFill: Color {
        Color.jbiAccent(for: colorScheme)
    }

    private var buttonText: Color {
        colorScheme == .dark ? JBITheme.darkBlue : .white
    }

    private var headerDisplayName: String {
        guard let profile else { return "Just Bean It" }
        let displayName = profile.headerDisplayName
        return displayName == "Just Bean It" ? "@\(profile.username)" : displayName
    }

    private var isViewingOtherProfile: Bool {
        profile != nil && relationship != .currentUser
    }

    init(profileId: UUID? = nil, onSignedOut: @escaping () -> Void, ownsNavigationStack: Bool = true) {
        self.profileId = profileId
        self.onSignedOut = onSignedOut
        self.ownsNavigationStack = ownsNavigationStack
    }

    var body: some View {
        if ownsNavigationStack {
            NavigationStack(path: $navigationPath) {
                rootContent
                    .navigationDestination(for: UUID.self) { id in
                        ProfileView(profileId: id, onSignedOut: onSignedOut, ownsNavigationStack: false)
                    }
            }
        } else {
            rootContent
        }
    }

    private var rootContent: some View {
        GeometryReader { geometry in
            let headerHeight = geometry.safeAreaInsets.top + 42

            ZStack(alignment: .top) {
                AppScreenBackground()

                if isLoading {
                    ProgressView()
                        .tint(foregroundColor)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let profile {
                    profileContent(profile, geometry: geometry, headerHeight: headerHeight)
                }

                MainHeaderView(
                    displayName: headerDisplayName,
                    section: "profile",
                    onNotifications: { showNotifications = true },
                    onFindFriends: { showFriendSearch = true },
                    onMenu: { withAnimation(.easeInOut(duration: 0.18)) { showMenu.toggle() } }
                )
                .frame(height: headerHeight)
                .zIndex(1)

                if isViewingOtherProfile {
                    backButton(headerHeight: headerHeight)
                        .zIndex(1)
                }

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
                NotificationView(displayName: headerDisplayName)
            }
            .sheet(isPresented: $showFriendSearch, onDismiss: refreshCounts) {
                FriendSearchView { selected in
                    navigationPath.append(selected.id)
                }
            }
            .sheet(isPresented: $showFollowers, onDismiss: refreshCounts) {
                if let profile {
                    FollowersListView(profile: profile) { selected in
                        navigationPath.append(selected.id)
                    }
                }
            }
            .sheet(isPresented: $showFollowing, onDismiss: refreshCounts) {
                if let profile {
                    FollowingListView(profile: profile) { selected in
                        navigationPath.append(selected.id)
                    }
                }
            }
            .sheet(isPresented: $showEditProfile, onDismiss: refreshProfile) {
                if let profile {
                    EditProfileView(profile: profile) {
                        refreshProfile()
                    }
                }
            }
            .task(id: profileId) {
                await loadProfile()
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    private func profileContent(_ profile: UserProfile, geometry: GeometryProxy, headerHeight: CGFloat) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Color.clear
                    .frame(height: headerHeight + 16)

                profileSummary(profile)
                    .padding(.horizontal, 24)

                statsRow
                    .padding(.horizontal, 8)

                actionButton
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, -4)

                if let errorText {
                    Text(errorText)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.red.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 28)
                }

                Spacer(minLength: 520)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .scrollIndicators(.hidden)
        .scrollContentBackground(.hidden)
        .refreshable {
            await loadProfile()
        }
    }

    private func backButton(headerHeight: CGFloat) -> some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .heavy))
                    .foregroundStyle(foregroundColor)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Back")

            Spacer()
        }
        .padding(.top, headerHeight + 2)
        .padding(.leading, 10)
    }

    private func profileSummary(_ profile: UserProfile) -> some View {
        HStack(alignment: .center, spacing: 18) {
            VStack(alignment: .leading, spacing: 6) {
                Text(profile.displayName)
                    .font(.system(size: 34, weight: .heavy))
                    .foregroundStyle(foregroundColor)
                    .lineLimit(2)
                    .minimumScaleFactor(0.74)

                Text("@\(profile.username)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(secondaryColor)
                    .lineLimit(1)

                bioText(profile)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            ProfileAvatarView(profile: profile, size: 116)
        }
    }

    @ViewBuilder
    private func bioText(_ profile: UserProfile) -> some View {
        let trimmedBio = (profile.bio ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedBio.isEmpty {
            Text(trimmedBio)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(foregroundColor.opacity(0.85))
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)
        } else if relationship == .currentUser {
            Text("add a bio")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(secondaryColor.opacity(0.72))
        }
    }

    private var actionButton: some View {
        Button {
            handleActionButton()
        } label: {
            Text(isUpdatingRelationship ? "..." : relationship.actionTitle)
                .font(.system(size: 15, weight: .heavy))
                .foregroundStyle(buttonText)
                .frame(width: 176, height: 40)
                .background(buttonFill)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .disabled(isUpdatingRelationship || isSigningOut || relationship == .pending)
    }

    private var statsRow: some View {
        HStack(spacing: 0) {
            statColumn(number: counts.following, label: "following") {
                showFollowing = true
            }

            statColumn(number: counts.posts, label: "posts") {}

            statColumn(number: counts.followers, label: "followers") {
                showFollowers = true
            }
        }
    }

    private func statColumn(number: Int, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text("\(number)")
                    .font(.system(size: 20, weight: .heavy))
                    .foregroundStyle(foregroundColor)
                Text(label)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(secondaryColor)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    @MainActor
    private func loadProfile() async {
        isLoading = true
        errorText = nil

        do {
            let loaded: UserProfile
            if let profileId {
                loaded = try await service.fetchProfile(userId: profileId)
            } else {
                loaded = try await service.fetchCurrentProfile()
            }
            profile = loaded
            relationship = await service.relationship(to: loaded.id)
            counts = try await service.fetchFollowCounts(userId: loaded.id)
            isLoading = false
        } catch {
            print("ProfileView load failed:", error)
            errorText = "Could not load this profile. Try again."
            isLoading = false
        }
    }

    private func handleActionButton() {
        guard let profile else { return }

        if relationship == .currentUser {
            showEditProfile = true
            return
        }

        guard relationship == .notFollowing || relationship == .following else { return }
        isUpdatingRelationship = true
        errorText = nil

        Task {
            do {
                if relationship == .following {
                    try await service.unfollowUser(targetUserId: profile.id)
                } else {
                    try await service.followUser(targetUserId: profile.id)
                }
                let nextRelationship = await service.relationship(to: profile.id)
                let nextCounts = try await service.fetchFollowCounts(userId: profile.id)
                await MainActor.run {
                    relationship = nextRelationship
                    counts = nextCounts
                    isUpdatingRelationship = false
                }
            } catch {
                print("ProfileView relationship update failed:", error)
                await MainActor.run {
                    errorText = "Could not update this follow. Try again."
                    isUpdatingRelationship = false
                }
            }
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
                print("ProfileView signOut failed:", error)
                await MainActor.run {
                    isSigningOut = false
                    errorText = "Could not log out. Try again."
                    showMenu = false
                }
            }
        }
    }

    private func refreshCounts() {
        guard let profile else { return }
        Task {
            let nextCounts = try? await service.fetchFollowCounts(userId: profile.id)
            await MainActor.run {
                if let nextCounts {
                    counts = nextCounts
                }
            }
        }
    }

    private func refreshProfile() {
        Task { await loadProfile() }
    }
}

#Preview {
    ProfileView(onSignedOut: {})
        .preferredColorScheme(.dark)
}
