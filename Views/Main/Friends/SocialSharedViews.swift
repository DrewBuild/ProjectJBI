import SwiftUI

struct SocialAvatarView: View {
    let profile: UserProfile
    var size: CGFloat = 48
    var borderColor: Color?

    @Environment(\.colorScheme) private var colorScheme

    private var foregroundColor: Color {
        colorScheme == .dark ? .white : .black
    }

    private var resolvedBorderColor: Color {
        borderColor ?? foregroundColor
    }

    var body: some View {
        ZStack {
            if let urlText = profile.profilePhotoURL, let url = URL(string: urlText) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    default:
                        placeholder
                    }
                }
            } else {
                placeholder
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .overlay(Circle().stroke(resolvedBorderColor.opacity(0.82), lineWidth: max(1, size / 32)))
        .contentShape(Circle())
    }

    private var placeholder: some View {
        Circle()
            .fill(foregroundColor.opacity(0.12))
            .overlay(
                Text(profile.initials)
                    .font(.system(size: size * 0.34, weight: .heavy))
                    .foregroundStyle(foregroundColor)
            )
    }
}

struct SocialUserRowView: View {
    let profile: UserProfile
    let relationship: ProfileRelationship
    let isUpdating: Bool
    let action: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    private var foregroundColor: Color {
        colorScheme == .dark ? .white : .black
    }

    private var buttonFill: Color {
        relationship == .notFollowing ? Color.jbiAccent(for: colorScheme) : foregroundColor.opacity(0.12)
    }

    private var buttonText: Color {
        if relationship == .notFollowing {
            return colorScheme == .dark ? JBITheme.darkBlue : .white
        }
        return foregroundColor
    }

    var body: some View {
        HStack(spacing: 12) {
            SocialAvatarView(profile: profile, size: 48)

            VStack(alignment: .leading, spacing: 3) {
                Text(profile.displayName)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(foregroundColor)
                    .lineLimit(1)

                Text("@\(profile.username)")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(foregroundColor.opacity(0.62))
                    .lineLimit(1)
            }

            Spacer(minLength: 10)

            if relationship != .currentUser {
                Button(action: action) {
                    Text(isUpdating ? "..." : relationship.actionTitle)
                        .font(.system(size: 12, weight: .heavy))
                        .foregroundStyle(buttonText)
                        .frame(width: 88, height: 32)
                        .background(buttonFill)
                        .clipShape(Capsule())
                        .overlay(
                            Capsule()
                                .stroke(foregroundColor.opacity(0.22), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
                .disabled(isUpdating || relationship == .pending)
            }
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }
}
