import SwiftUI

struct FriendSearchView: View {
    let onProfileSelected: (UserProfile) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    @State private var query = ""
    @State private var results: [UserProfile] = []
    @State private var relationships: [UUID: ProfileRelationship] = [:]
    @State private var updatingIds: Set<UUID> = []
    @State private var errorText: String?
    @State private var searchTask: Task<Void, Never>?

    private let service = ProfileService()

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

                VStack(spacing: 16) {
                    searchField
                        .padding(.horizontal, 18)
                        .padding(.top, 12)

                    if let errorText {
                        Text(errorText)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(.red.opacity(0.9))
                            .padding(.horizontal, 18)
                    }

                    ScrollView {
                        LazyVStack(spacing: 2) {
                            ForEach(results) { profile in
                                Button {
                                    onProfileSelected(profile)
                                    dismiss()
                                } label: {
                                    UserSearchRowView(
                                        profile: profile,
                                        relationship: relationships[profile.id] ?? .notFollowing,
                                        isUpdating: updatingIds.contains(profile.id)
                                    ) {
                                        toggleFollow(profile)
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 18)
                        .padding(.bottom, 24)
                    }
                    .scrollContentBackground(.hidden)
                    .refreshable {
                        await refreshSearch()
                    }
                }
            }
            .navigationTitle("friends")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(colorScheme, for: .navigationBar)
            .toolbarBackground(backgroundColor, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(foregroundColor)
                        .font(.system(size: 14, weight: .bold))
                }
            }
            .onChange(of: query) { _, newValue in
                scheduleSearch(newValue)
            }
            .onDisappear {
                searchTask?.cancel()
            }
        }
    }

    private var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(foregroundColor.opacity(0.65))

            TextField("Search friends", text: $query)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .foregroundStyle(foregroundColor)
                .font(.system(size: 16, weight: .semibold))
                .tint(foregroundColor)
        }
        .padding(.horizontal, 14)
        .frame(height: 44)
        .background(foregroundColor.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(foregroundColor.opacity(0.14), lineWidth: 1)
        )
    }

    private func scheduleSearch(_ value: String) {
        searchTask?.cancel()
        errorText = nil

        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 2 else {
            results = []
            relationships = [:]
            return
        }

        searchTask = Task {
            try? await Task.sleep(nanoseconds: 400_000_000)
            if Task.isCancelled { return }
            await runSearch(trimmed)
        }
    }

    @MainActor
    private func runSearch(_ text: String) async {
        do {
            let profiles = try await service.searchProfiles(query: text)
            var nextRelationships: [UUID: ProfileRelationship] = [:]
            for profile in profiles {
                nextRelationships[profile.id] = await service.relationship(to: profile.id)
            }
            results = profiles
            relationships = nextRelationships
        } catch {
            print("FriendSearchView search failed:", error)
            errorText = "Could not search friends. Try again."
        }
    }

    private func toggleFollow(_ profile: UserProfile) {
        guard !updatingIds.contains(profile.id) else { return }
        updatingIds.insert(profile.id)

        Task {
            do {
                let relationship = relationships[profile.id] ?? .notFollowing
                if relationship == .following {
                    try await service.unfollowUser(targetUserId: profile.id)
                } else if relationship == .notFollowing {
                    try await service.followUser(targetUserId: profile.id)
                }
                let updated = await service.relationship(to: profile.id)
                await MainActor.run {
                    relationships[profile.id] = updated
                    updatingIds.remove(profile.id)
                }
            } catch {
                print("FriendSearchView follow failed:", error)
                await MainActor.run {
                    errorText = "Could not update this follow. Try again."
                    updatingIds.remove(profile.id)
                }
            }
        }
    }

    private func refreshSearch() async {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 2 else { return }
        await runSearch(trimmed)
    }
}
