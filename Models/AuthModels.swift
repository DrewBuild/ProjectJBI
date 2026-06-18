import Foundation

struct ProfileInsert: Codable {
    let id: UUID
    let firstName: String
    let lastName: String
    let username: String
    let email: String
    let bio: String?

    enum CodingKeys: String, CodingKey {
        case id
        case firstName = "first_name"
        case lastName = "last_name"
        case username
        case email
        case bio
    }
}

struct UsernameAvailabilityResponse: Codable {
    let available: Bool
    let reason: String
}

struct UserProfile: Codable, Identifiable, Hashable {
    let id: UUID
    var firstName: String
    var lastName: String
    var username: String
    var email: String?
    var bio: String?
    var profilePhotoURL: String?
    var backdropPhotoURL: String?
    var backdropOffsetX: Double?
    var backdropOffsetY: Double?
    var backdropScale: Double?
    var isPrivate: Bool?

    var displayName: String {
        let name = [firstName, lastName]
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: " ")
        return name.isEmpty ? username : name
    }

    var initials: String {
        let first = firstName.first.map(String.init) ?? ""
        let last = lastName.first.map(String.init) ?? ""
        let combined = first + last
        return combined.isEmpty ? String(username.prefix(1)).uppercased() : combined.uppercased()
    }

    var headerDisplayName: String {
        let trimmedFirst = firstName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedLast = lastName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedFirst.isEmpty else { return "Just Bean It" }
        guard let lastInitial = trimmedLast.first else { return trimmedFirst }
        return "\(trimmedFirst) \(String(lastInitial).uppercased())."
    }

    enum CodingKeys: String, CodingKey {
        case id
        case firstName = "first_name"
        case lastName = "last_name"
        case username
        case email
        case bio
        case profilePhotoURL = "profile_photo_url"
        case backdropPhotoURL = "backdrop_photo_url"
        case backdropOffsetX = "backdrop_offset_x"
        case backdropOffsetY = "backdrop_offset_y"
        case backdropScale = "backdrop_scale"
        case isPrivate = "is_private"
    }
}

struct ProfileUpdate: Encodable {
    let firstName: String
    let lastName: String
    let bio: String?
    let profilePhotoURL: String?
    let backdropPhotoURL: String?
    let backdropOffsetX: Double
    let backdropOffsetY: Double
    let backdropScale: Double

    enum CodingKeys: String, CodingKey {
        case firstName = "first_name"
        case lastName = "last_name"
        case bio
        case profilePhotoURL = "profile_photo_url"
        case backdropPhotoURL = "backdrop_photo_url"
        case backdropOffsetX = "backdrop_offset_x"
        case backdropOffsetY = "backdrop_offset_y"
        case backdropScale = "backdrop_scale"
    }
}

struct FollowRecord: Codable, Identifiable, Hashable {
    let id: UUID?
    let followerId: UUID
    let followingId: UUID
    let createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case followerId = "follower_id"
        case followingId = "following_id"
        case createdAt = "created_at"
    }
}

struct FollowInsert: Encodable {
    let followerId: UUID
    let followingId: UUID

    enum CodingKeys: String, CodingKey {
        case followerId = "follower_id"
        case followingId = "following_id"
    }
}

struct FollowCounts: Equatable {
    var following: Int = 0
    var followers: Int = 0
    var posts: Int = 0
}

enum ProfileRelationship: Equatable {
    case currentUser
    case notFollowing
    case following
    case pending

    var actionTitle: String {
        switch self {
        case .currentUser: return "edit"
        case .notFollowing: return "follow"
        case .following: return "following"
        case .pending: return "pending"
        }
    }
}
