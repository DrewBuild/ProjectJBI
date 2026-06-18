import SwiftUI

struct UserSearchRowView: View {
    let profile: UserProfile
    let relationship: ProfileRelationship
    let isUpdating: Bool
    let action: () -> Void

    var body: some View {
        SocialUserRowView(
            profile: profile,
            relationship: relationship,
            isUpdating: isUpdating,
            action: action
        )
    }
}
