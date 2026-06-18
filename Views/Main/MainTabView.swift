import SwiftUI

struct MainTabView: View {
    let onSignedOut: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    @State private var selectedTab: MainTab = .feed
    @State private var headerDisplayName = "Just Bean It"

    private let profileService = ProfileService()

    var body: some View {
        tabContent
            .tint(Color.jbiAccent(for: colorScheme))
            .accentColor(Color.jbiAccent(for: colorScheme))
            .task {
                await loadHeaderDisplayName()
            }
    }

    @ViewBuilder
    private var tabContent: some View {
        if #available(iOS 26.0, *) {
            tabs
                .tabBarMinimizeBehavior(.onScrollDown)
        } else {
            tabs
        }
    }

    private var tabs: some View {
        TabView(selection: $selectedTab) {
            FeedView(displayName: headerDisplayName, onSignedOut: onSignedOut)
                .tabItem {
                    Label("Feed", systemImage: "mug.fill")
                }
                .tag(MainTab.feed)

            DiscoverView(displayName: headerDisplayName, onSignedOut: onSignedOut)
                .tabItem {
                    Label("Discover", systemImage: "storefront.fill")
                }
                .tag(MainTab.discover)

            PostView(displayName: headerDisplayName, onSignedOut: onSignedOut) {
                selectedTab = .feed
            }
                .tabItem {
                    Label("Post", systemImage: "plus.viewfinder")
                }
                .tag(MainTab.post)

            StatsView(displayName: headerDisplayName, onSignedOut: onSignedOut)
                .tabItem {
                    Label("Stats", systemImage: "flame.fill")
                }
                .tag(MainTab.stats)

            ProfileView(onSignedOut: onSignedOut)
                .tabItem {
                    Label("Profile", systemImage: "person.crop.rectangle.fill")
                }
                .tag(MainTab.profile)
        }
    }

    @MainActor
    private func loadHeaderDisplayName() async {
        do {
            headerDisplayName = try await profileService.fetchCurrentProfile().headerDisplayName
        } catch {
            print("MainTabView profile display name load failed:", error)
        }
    }
}

#Preview {
    MainTabView(onSignedOut: {})
}
