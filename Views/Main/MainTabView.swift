import SwiftUI

struct MainTabView: View {
    let onSignedOut: () -> Void

    @State private var selectedTab: MainTab = .feed
    @State private var isTabBarMinimized = false

    private let displayName = "Drew J."
    private let hotPink = Color(red: 1.0, green: 0.12, blue: 0.72)

    var body: some View {
        ZStack {
            tabContent
                .tint(hotPink)

            if isTabBarMinimized {
                VStack {
                    Spacer()
                    restoreButton
                        .padding(.bottom, 26)
                        .transition(.opacity.combined(with: .scale(scale: 0.85)))
                }
                .allowsHitTesting(true)
            }
        }
        .animation(.easeInOut(duration: 0.22), value: isTabBarMinimized)
    }

    @ViewBuilder
    private var tabContent: some View {
        if #available(iOS 26.0, *) {
            baseTabView
                .tabBarMinimizeBehavior(.onScrollDown)
        } else {
            baseTabView
        }
    }

    private var baseTabView: some View {
        TabView(selection: $selectedTab) {
            FeedView(displayName: displayName, isTabBarMinimized: $isTabBarMinimized)
                .tabItem {
                    Label("Feed", systemImage: "newspaper.fill")
                }
                .tag(MainTab.feed)

            DiscoverView(displayName: displayName, isTabBarMinimized: $isTabBarMinimized)
                .tabItem {
                    Label("Discover", systemImage: "map.fill")
                }
                .tag(MainTab.discover)

            PostView(displayName: displayName, isTabBarMinimized: $isTabBarMinimized)
                .tabItem {
                    Label("Post", systemImage: "plus.viewfinder")
                }
                .tag(MainTab.post)

            StatsView(displayName: displayName, isTabBarMinimized: $isTabBarMinimized)
                .tabItem {
                    Label("Stats", systemImage: "flame.fill")
                }
                .tag(MainTab.stats)

            ProfileView(
                displayName: displayName,
                isTabBarMinimized: $isTabBarMinimized,
                onSignedOut: onSignedOut
            )
            .tabItem {
                Label("Profile", systemImage: "person.crop.rectangle.fill")
            }
            .tag(MainTab.profile)
        }
    }

    private var restoreButton: some View {
        Button {
            NotificationCenter.default.post(name: .jbiRevealTabBar, object: nil)
        } label: {
            Image(systemName: "rectangle.stack")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(hotPink)
                .frame(width: 52, height: 52)
                .background(.ultraThinMaterial, in: Circle())
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.28), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.25), radius: 10, x: 0, y: 4)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Show tab bar")
    }
}

#Preview {
    MainTabView(onSignedOut: {})
}
