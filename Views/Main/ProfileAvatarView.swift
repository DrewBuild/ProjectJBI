import SwiftUI

struct ProfileAvatarView: View {
    let profile: UserProfile
    var size: CGFloat = 112

    @Environment(\.colorScheme) private var colorScheme

    private var foregroundColor: Color {
        colorScheme == .dark ? .white : .black
    }

    private var placeholderFill: Color {
        colorScheme == .dark ? Color.white.opacity(0.12) : Color.black.opacity(0.08)
    }

    private var borderColor: Color {
        colorScheme == .dark ? .white : .black
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
        .overlay(Circle().stroke(borderColor.opacity(0.85), lineWidth: 2))
        .contentShape(Circle())
    }

    private var placeholder: some View {
        Circle()
            .fill(placeholderFill)
            .overlay(
                Text(profile.initials)
                    .font(.system(size: size * 0.34, weight: .heavy))
                    .foregroundStyle(foregroundColor)
            )
    }
}
