import SwiftUI

struct EmailConfirmView: View {
    let email: String

    @Environment(\.colorScheme) private var colorScheme

    private var foregroundColor: Color {
        colorScheme == .dark ? .white : .black
    }

    private var secondaryColor: Color {
        foregroundColor.opacity(0.78)
    }

    private var buttonFill: Color {
        Color.jbiAccent(for: colorScheme)
    }

    private var buttonText: Color {
        colorScheme == .dark ? JBITheme.darkBlue : .white
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                SolidAppBackground()

                confirmationPanel(in: geometry)
                    .position(x: geometry.size.width / 2, y: geometry.size.height * 0.75)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .contentShape(Rectangle())
            .onTapGesture {
                hideKeyboard()
            }
        }
        .ignoresSafeArea()
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
    }

    private func confirmationPanel(in geometry: GeometryProxy) -> some View {
        VStack(spacing: 11) {
            Text("WELCOME")
                .font(.system(size: 24, weight: .heavy))
                .foregroundStyle(foregroundColor)
                .padding(.top, 30)

            Text("We just sent you\nan email to\n\(displayEmail)")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(foregroundColor)
                .multilineTextAlignment(.center)
                .lineSpacing(1)

            Text("Tap the confirmation link in your email, then log in.")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(foregroundColor.opacity(0.9))
                .multilineTextAlignment(.center)
                .padding(.top, 5)

            Button {
                print("Submit confirmation tapped")
            } label: {
                Text("log in")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(buttonText)
                    .frame(width: 88, height: 26)
                    .background(buttonFill)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .padding(.top, 6)

            Spacer(minLength: 0)
        }
        .frame(width: geometry.size.width, height: geometry.size.height * 0.50)
        .background {
            Rectangle()
                .fill(.ultraThinMaterial)
        }
        .clipShape(.rect(topLeadingRadius: 34, topTrailingRadius: 34))
        .overlay(
            UnevenRoundedRectangle(topLeadingRadius: 34, topTrailingRadius: 34)
                .stroke(secondaryColor.opacity(0.28), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.18), radius: 24, x: 0, y: -8)
    }

    private var displayEmail: String {
        email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "your email" : email
    }
}

#Preview {
    EmailConfirmView(email: "drew@example.com")
}
