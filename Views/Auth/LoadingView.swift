import SwiftUI

struct LoadingView: View {
    @Environment(\.colorScheme) private var colorScheme

    private var foregroundColor: Color {
        colorScheme == .dark ? .white : .black
    }

    private var characterAssetName: String {
        colorScheme == .dark ? "JBICharacterL" : "JBICharacterD"
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                SolidAppBackground()

                VStack(spacing: 14) {
                    Image(characterAssetName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: min(geometry.size.width * 0.46, 220))
                        .accessibilityHidden(true)

                    Text("Just Bean It")
                        .font(.system(size: 18, weight: .heavy))
                        .foregroundStyle(foregroundColor)
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .ignoresSafeArea()
        }
        .ignoresSafeArea()
    }
}

#Preview {
    LoadingView()
}
