import SwiftUI

struct FollowersListView: View {
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
            title: "followers",
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
            let loaded = try await service.fetchFollowers(userId: profile.id)
            var nextRelationships: [UUID: ProfileRelationship] = [:]
            for loadedProfile in loaded {
                nextRelationships[loadedProfile.id] = await service.relationship(to: loadedProfile.id)
            }
            profiles = loaded
            relationships = nextRelationships
            isLoading = false
        } catch {
            print("FollowersListView load failed:", error)
            errorText = "Could not load followers. Try again."
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
                print("FollowersListView follow failed:", error)
                await MainActor.run {
                    errorText = "Could not update this follow. Try again."
                    updatingIds.remove(selected.id)
                }
            }
        }
    }
}
