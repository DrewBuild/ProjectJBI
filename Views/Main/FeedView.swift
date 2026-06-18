import SwiftUI

struct FeedView: View {
    let displayName: String
    @Binding var isTabBarMinimized: Bool

    @State private var lastOffset: CGFloat = 0

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                AppScreenBackground()

                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(spacing: 0) {
                            Color.clear
                                .frame(height: 0)
                                .id("top")

                            MainHeaderView(displayName: displayName, section: "feed")
                                .padding(.top, geometry.safeAreaInsets.top + 34)

                            Spacer(minLength: 1200)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .scrollContentBackground(.hidden)
                    .onScrollGeometryChange(for: CGFloat.self) { geo in
                        geo.contentOffset.y
                    } action: { _, newOffset in
                        updateMinimized(newOffset: newOffset)
                    }
                    .onReceive(NotificationCenter.default.publisher(for: .jbiRevealTabBar)) { _ in
                        withAnimation(.easeInOut(duration: 0.25)) {
                            proxy.scrollTo("top", anchor: .top)
                        }
                        if isTabBarMinimized { isTabBarMinimized = false }
                    }
                }
            }
            .ignoresSafeArea()
        }
    }

    private func updateMinimized(newOffset: CGFloat) {
        let delta = newOffset - lastOffset
        if delta > 8, !isTabBarMinimized {
            isTabBarMinimized = true
        } else if (delta < -8 || newOffset < 8), isTabBarMinimized {
            isTabBarMinimized = false
        }
        lastOffset = newOffset
    }
}

#Preview {
    FeedView(displayName: "Drew J.", isTabBarMinimized: .constant(false))
}
