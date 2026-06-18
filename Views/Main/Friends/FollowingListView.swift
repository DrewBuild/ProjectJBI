import SwiftUI

struct FollowingListView: View {
    let profile: UserProfile
    let onProfileSelected: (UserProfile) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var profiles: [UserProfile] = []
    @State private var relationships: [UUID: ProfileRelationship] = [:]
    @State private var updatingIds: Set<UUID> = []
    @State private var errorText: String?
    @State private var isLoading = true

    private let service = ProfileService()

    var body: some View {
        SocialListContainerView(
            title: "following",
            isLoading: isLoading,
            errorText: errorText,
            profiles: profiles,
            relationships: relationships,
            updatingIds: updatingIds,
            onClose: { dismiss() },
            onProfileSelected: { selected in
                onProfileSelected(selected)
                dismiss()
            },
            onToggleFollow: toggleFollow
        )
        .task { await load() }
        .refreshable {
            await load()
        }
    }

    @MainActor
    private func load() async {
        isLoading = true
        errorText = nil
        do {
            let loaded = try await service.fetchFollowing(userId: profile.id)
            var nextRelationships: [UUID: ProfileRelationship] = [:]
            for loadedProfile in loaded {
                nextRelationships[loadedProfile.id] = await service.relationship(to: loadedProfile.id)
            }
            profiles = loaded
            relationships = nextRelationships
            isLoading = false
        } catch {
            print("FollowingListView load failed:", error)
            errorText = "Could not load following. Try again."
            isLoading = false
        }
    }

    private func toggleFollow(_ selected: UserProfile) {
        guard !updatingIds.contains(selected.id) else { return }
        updatingIds.insert(selected.id)

        Task {
            do {
                let relationship = relationships[selected.id] ?? .notFollowing
                if relationship == .following {
                    try await service.unfollowUser(targetUserId: selected.id)
                } else if relationship == .notFollowing {
                    try await service.followUser(targetUserId: selected.id)
                }
                let updated = await service.relationship(to: selected.id)
                await MainActor.run {
                    relationships[selected.id] = updated
                    updatingIds.remove(selected.id)
                }
            } catch {
                print("FollowingListView follow failed:", error)
                await MainActor.run {
                    errorText = "Could not update this follow. Try again."
                    updatingIds.remove(selected.id)
                }
            }
        }
    }
}

struct SocialListContainerView: View {
    let title: String
    let isLoading: Bool
    let errorText: String?
    let profiles: [UserProfile]
    let relationships: [UUID: ProfileRelationship]
    let updatingIds: Set<UUID>
    let onClose: () -> Void
    let onProfileSelected: (UserProfile) -> Void
    let onToggleFollow: (UserProfile) -> Void

    @Environment(\.colorScheme) private var colorScheme

    private var foregroundColor: Color {
        colorScheme == .dark ? .white : .black
    }

    private var backgroundColor: Color {
        colorScheme == .dark ? .black : .white
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppScreenBackground()

                if isLoading {
                    ProgressView()
                        .tint(foregroundColor)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 2) {
                            if let errorText {
                                Text(errorText)
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundStyle(.red.opacity(0.9))
                                    .padding(.vertical, 12)
                            }

                            ForEach(profiles) { profile in
                                Button {
                                    onProfileSelected(profile)
                                } label: {
                                    SocialUserRowView(
                                        profile: profile,
                                        relationship: relationships[profile.id] ?? .notFollowing,
                                        isUpdating: updatingIds.contains(profile.id)
                                    ) {
                                        onToggleFollow(profile)
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 18)
                        .padding(.vertical, 14)
                    }
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(colorScheme, for: .navigationBar)
            .toolbarBackground(backgroundColor, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { onClose() }
                        .foregroundStyle(foregroundColor)
                        .font(.system(size: 14, weight: .bold))
                }
            }
        }
    }
}
