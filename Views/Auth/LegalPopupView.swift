import SwiftUI

enum LegalDocument {
    case terms
    case privacy

    var title: String {
        switch self {
        case .terms:
            return "Terms of Service"
        case .privacy:
            return "Privacy Policy"
        }
    }

    var bodyText: String {
        switch self {
        case .terms:
            return """
            Welcome to Just Bean It. These placeholder Terms of Service explain the basic rules for using the app. By creating an account, you agree to use Just Bean It respectfully, provide accurate account information, and avoid posting harmful, offensive, misleading, or illegal content.

            Just Bean It is a social coffee discovery app. User posts, ratings, usernames, photos, and profile information may be visible to other users depending on your privacy settings. You are responsible for the content you share.

            You may not misuse the app, attempt to access another user's account, scrape data, impersonate others, or interfere with app security. We may remove content or restrict access if these terms are violated.

            These terms are temporary placeholder text and will be replaced with a full legal policy before public launch.
            """
        case .privacy:
            return """
            This placeholder Privacy Policy explains how Just Bean It may handle information during app use. When you create an account, we may collect your name, username, email address, password credentials handled securely by Supabase Auth, profile information, posts, ratings, photos, and app activity.

            We use this information to create your account, personalize your experience, show coffee recommendations, support social features, improve app performance, and keep the community safe.

            Passwords are managed through Supabase Auth and should not be stored directly in profile tables. We do not sell personal information in this placeholder policy.

            Some information, such as your username, profile, posts, and ratings, may be visible to other users depending on app settings. This policy is temporary placeholder text and will be replaced with a full legal policy before public launch.
            """
        }
    }
}

struct LegalPopupView: View {
    let document: LegalDocument
    let onClose: () -> Void

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.opacity(0.35)
                    .ignoresSafeArea()
                    .onTapGesture(perform: onClose)

                VStack(spacing: 14) {
                    HStack {
                        Text(document.title)
                            .font(.system(size: 24, weight: .heavy))
                            .foregroundStyle(.white)

                        Spacer()

                        Button(action: onClose) {
                            Image(systemName: "xmark")
                                .font(.system(size: 14, weight: .heavy))
                            .foregroundStyle(.white)
                                .frame(width: 32, height: 32)
                                .background(Color.white.opacity(0.16))
                                .clipShape(Circle())
                        }
                        .buttonStyle(.plain)
                    }

                    ScrollView {
                        Text(document.bodyText)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.88))
                            .lineSpacing(4)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.bottom, 10)
                    }
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                }
                .padding(22)
                .frame(
                    width: min(max(geometry.size.width * 0.9, geometry.size.width * 0.86), geometry.size.width * 0.92),
                    height: min(max(geometry.size.height * 0.74, geometry.size.height * 0.70), geometry.size.height * 0.78)
                )
                .background {
                    ZStack {
                        RoundedRectangle(cornerRadius: 34, style: .continuous)
                            .fill(.regularMaterial)

                        RoundedRectangle(cornerRadius: 34, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.48, green: 0.05, blue: 0.52).opacity(0.50),
                                        Color(red: 0.95, green: 0.38, blue: 0.62).opacity(0.22)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 34, style: .continuous)
                        .stroke(Color.white.opacity(0.28), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.3), radius: 28, x: 0, y: 12)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .ignoresSafeArea()
        }
        .ignoresSafeArea()
    }
}

#Preview {
    LegalPopupView(document: .terms) {}
}
