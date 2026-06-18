import Foundation
import Supabase
#if canImport(UIKit)
import UIKit
#endif

enum ProfileServiceError: LocalizedError {
    case missingSession
    case profileNotFound
    case uploadFailed
    case message(String)

    var errorDescription: String? {
        switch self {
        case .missingSession:
            return "Please log in again."
        case .profileNotFound:
            return "We could not find that profile."
        case .uploadFailed:
            return "We could not upload that photo. Try again."
        case .message(let message):
            return message
        }
    }
}

final class ProfileService {
    private let client = SupabaseManager.shared.client

    func currentUserId() async throws -> UUID {
        do {
            return try await client.auth.session.user.id
        } catch {
            print("currentUserId failed:", error)
            throw ProfileServiceError.missingSession
        }
    }

    func fetchCurrentProfile() async throws -> UserProfile {
        try await fetchProfile(userId: currentUserId())
    }

    func fetchProfile(userId: UUID) async throws -> UserProfile {
        do {
            let profiles: [UserProfile] = try await client
                .from("profiles")
                .select()
                .eq("id", value: userId.uuidString)
                .limit(1)
                .execute()
                .value

            guard let profile = profiles.first else {
                throw ProfileServiceError.profileNotFound
            }
            return profile
        } catch let error as ProfileServiceError {
            throw error
        } catch {
            print("fetchProfile failed:", error)
            throw ProfileServiceError.profileNotFound
        }
    }

    func searchProfiles(query: String) async throws -> [UserProfile] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard trimmed.count >= 2 else { return [] }
        let currentId = try? await currentUserId()

        do {
            let profiles: [UserProfile] = try await client
                .from("profiles")
                .select()
                .limit(100)
                .execute()
                .value

            return profiles
                .filter { profile in
                    profile.id != currentId && (
                        profile.username.lowercased().contains(trimmed) ||
                        profile.firstName.lowercased().contains(trimmed) ||
                        profile.lastName.lowercased().contains(trimmed)
                    )
                }
                .prefix(30)
                .map { $0 }
        } catch {
            print("searchProfiles failed:", error)
            throw ProfileServiceError.message("Could not search friends. Try again.")
        }
    }

    func followUser(targetUserId: UUID) async throws {
        let currentId = try await currentUserId()
        guard currentId != targetUserId else { return }

        do {
            try await client
                .from("follows")
                .insert(FollowInsert(followerId: currentId, followingId: targetUserId))
                .execute()
        } catch {
            let text = String(describing: error).lowercased()
            if text.contains("duplicate") || text.contains("23505") {
                return
            }
            print("followUser failed:", error)
            throw ProfileServiceError.message("Could not follow this profile. Try again.")
        }
    }

    func unfollowUser(targetUserId: UUID) async throws {
        let currentId = try await currentUserId()

        do {
            try await client
                .from("follows")
                .delete()
                .eq("follower_id", value: currentId.uuidString)
                .eq("following_id", value: targetUserId.uuidString)
                .execute()
        } catch {
            print("unfollowUser failed:", error)
            throw ProfileServiceError.message("Could not update this follow. Try again.")
        }
    }

    func relationship(to targetUserId: UUID) async -> ProfileRelationship {
        guard let currentId = try? await currentUserId() else { return .notFollowing }
        if currentId == targetUserId { return .currentUser }

        do {
            let rows: [FollowRecord] = try await client
                .from("follows")
                .select()
                .eq("follower_id", value: currentId.uuidString)
                .eq("following_id", value: targetUserId.uuidString)
                .limit(1)
                .execute()
                .value
            return rows.isEmpty ? .notFollowing : .following
        } catch {
            print("relationship lookup failed:", error)
            return .notFollowing
        }
    }

    func fetchFollowers(userId: UUID) async throws -> [UserProfile] {
        do {
            let rows: [FollowRecord] = try await client
                .from("follows")
                .select()
                .eq("following_id", value: userId.uuidString)
                .execute()
                .value

            var profiles: [UserProfile] = []
            for row in rows {
                do {
                    profiles.append(try await fetchProfile(userId: row.followerId))
                } catch {
                    print("fetchFollowers skipped profile:", error)
                }
            }
            return profiles
        } catch {
            print("fetchFollowers failed:", error)
            throw ProfileServiceError.message("Could not load followers. Try again.")
        }
    }

    func fetchFollowing(userId: UUID) async throws -> [UserProfile] {
        do {
            let rows: [FollowRecord] = try await client
                .from("follows")
                .select()
                .eq("follower_id", value: userId.uuidString)
                .execute()
                .value

            var profiles: [UserProfile] = []
            for row in rows {
                do {
                    profiles.append(try await fetchProfile(userId: row.followingId))
                } catch {
                    print("fetchFollowing skipped profile:", error)
                }
            }
            return profiles
        } catch {
            print("fetchFollowing failed:", error)
            throw ProfileServiceError.message("Could not load following. Try again.")
        }
    }

    func fetchFollowCounts(userId: UUID) async throws -> FollowCounts {
        async let followers = fetchFollowersCount(userId: userId)
        async let following = fetchFollowingCount(userId: userId)
        async let posts = fetchPostCount(userId: userId)
        return FollowCounts(following: try await following, followers: try await followers, posts: try await posts)
    }

    func fetchPostCount(userId: UUID) async throws -> Int {
        do {
            struct PostRow: Decodable { let id: UUID? }
            let rows: [PostRow] = try await client
                .from("posts")
                .select("id")
                .eq("user_id", value: userId.uuidString)
                .execute()
                .value
            return rows.count
        } catch {
            print("fetchPostCount failed or posts table missing:", error)
            return 0
        }
    }

    func updateProfile(
        profile: UserProfile,
        firstName: String,
        lastName: String,
        bio: String?,
        profilePhotoURL: String?,
        backdropPhotoURL: String?
    ) async throws {
        let currentId = try await currentUserId()
        guard currentId == profile.id else { throw ProfileServiceError.missingSession }

        let update = ProfileUpdate(
            firstName: firstName.trimmingCharacters(in: .whitespacesAndNewlines),
            lastName: lastName.trimmingCharacters(in: .whitespacesAndNewlines),
            bio: bio?.trimmingCharacters(in: .whitespacesAndNewlines),
            profilePhotoURL: profilePhotoURL,
            backdropPhotoURL: backdropPhotoURL,
            backdropOffsetX: profile.backdropOffsetX ?? 0,
            backdropOffsetY: profile.backdropOffsetY ?? 0,
            backdropScale: profile.backdropScale ?? 1
        )

        do {
            try await client
                .from("profiles")
                .update(update)
                .eq("id", value: currentId.uuidString)
                .execute()
        } catch {
            print("updateProfile failed:", error)
            throw ProfileServiceError.message("Could not save your profile. Try again.")
        }
    }

    #if canImport(UIKit)
    func uploadProfilePhoto(_ image: UIImage, userId: UUID) async throws -> String {
        try await uploadImage(image, bucket: "avatars", path: "\(userId.uuidString)/profile.jpg", compression: 0.78)
    }

    #endif

    func removeProfilePhoto(userId: UUID) async throws {
        try await removeStorageObject(bucket: "avatars", path: "\(userId.uuidString)/profile.jpg")
    }


    private func fetchFollowersCount(userId: UUID) async throws -> Int {
        let rows: [FollowRecord] = try await client
            .from("follows")
            .select()
            .eq("following_id", value: userId.uuidString)
            .execute()
            .value
        return rows.count
    }

    private func fetchFollowingCount(userId: UUID) async throws -> Int {
        let rows: [FollowRecord] = try await client
            .from("follows")
            .select()
            .eq("follower_id", value: userId.uuidString)
            .execute()
            .value
        return rows.count
    }

    #if canImport(UIKit)
    private func uploadImage(_ image: UIImage, bucket: String, path: String, compression: CGFloat) async throws -> String {
        guard let data = image.jpegData(compressionQuality: compression) else {
            throw ProfileServiceError.uploadFailed
        }

        do {
            try await client.storage
                .from(bucket)
                .upload(path, data: data, options: FileOptions(contentType: "image/jpeg", upsert: true))
            let publicURL = try client.storage.from(bucket).getPublicURL(path: path)
            return publicURL.absoluteString
        } catch {
            print("uploadImage failed:", error)
            throw ProfileServiceError.uploadFailed
        }
    }
    #endif

    private func removeStorageObject(bucket: String, path: String) async throws {
        do {
            try await client.storage
                .from(bucket)
                .remove(paths: [path])
        } catch {
            print("removeStorageObject failed:", error)
        }
    }
}
