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
