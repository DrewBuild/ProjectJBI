import SwiftUI

struct LoadingView: View {
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Image("JBIBackground")
                    .resizable()
                    .scaledToFill()
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .clipped()
                    .ignoresSafeArea()

                VStack(spacing: 14) {
                    Image("JBICharacter")
                        .resizable()
                        .scaledToFit()
                        .frame(width: min(geometry.size.width * 0.46, 220))
                        .accessibilityHidden(true)

                    Text("Just Bean It")
                        .font(.system(size: 18, weight: .heavy))
                        .foregroundStyle(.white)
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
