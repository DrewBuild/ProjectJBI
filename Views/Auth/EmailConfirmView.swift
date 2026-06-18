import SwiftUI

struct EmailConfirmView: View {
    let email: String

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Image("JBIBackground")
                    .resizable()
                    .scaledToFill()
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .clipped()
                    .ignoresSafeArea()

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
                .foregroundStyle(.white)
                .padding(.top, 30)

            Text("We just sent you\nan email to\n\(displayEmail)")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .lineSpacing(1)

            Text("Tap the confirmation link in your email, then log in.")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(.white.opacity(0.9))
                .multilineTextAlignment(.center)
                .padding(.top, 5)

            Button {
                print("Submit confirmation tapped")
            } label: {
                Text("log in")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 88, height: 26)
                    .background(Color.black.opacity(0.82))
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .padding(.top, 6)

            Spacer(minLength: 0)
        }
        .frame(width: geometry.size.width, height: geometry.size.height * 0.50)
        .background {
            ZStack {
                Rectangle()
                    .fill(.ultraThinMaterial)

                Rectangle()
                    .fill(Color(red: 0.45, green: 0.05, blue: 0.45).opacity(0.42))
            }
        }
        .clipShape(.rect(topLeadingRadius: 34, topTrailingRadius: 34))
        .overlay(
            UnevenRoundedRectangle(topLeadingRadius: 34, topTrailingRadius: 34)
                .stroke(Color.white.opacity(0.28), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.28), radius: 24, x: 0, y: -8)
    }

    private var displayEmail: String {
        email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "your email" : email
    }
}

#Preview {
    EmailConfirmView(email: "drew@example.com")
}
