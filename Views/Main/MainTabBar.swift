import SwiftUI

enum MainTab: CaseIterable, Hashable {
    case feed
    case discover
    case post
    case stats
    case profile

    var title: String {
        switch self {
        case .feed: return "feed"
        case .discover: return "discover"
        case .post: return "post"
        case .stats: return "stats"
        case .profile: return "profile"
        }
    }

    var symbol: String {
        switch self {
        case .feed: return "newspaper.fill"
        case .discover: return "map.fill"
        case .post: return "plus.viewfinder"
        case .stats: return "flame.fill"
        case .profile: return "person.crop.rectangle.fill"
        }
    }
}

struct MainTabBar: View {
    @Binding var selectedTab: MainTab

    private let hotPink = Color(red: 1.0, green: 0.12, blue: 0.72)
    private let tintTop = Color(red: 0.45, green: 0.20, blue: 0.55).opacity(0.45)
    private let tintBottom = Color(red: 0.28, green: 0.10, blue: 0.40).opacity(0.45)
    private let tabs = MainTab.allCases
    private let barHeight: CGFloat = 66
    private let indicatorHeight: CGFloat = 46

    private var selectedIndex: Int {
        tabs.firstIndex(of: selectedTab) ?? 0
    }

    var body: some View {
        GeometryReader { proxy in
            let totalWidth = proxy.size.width
            let itemWidth = totalWidth / CGFloat(tabs.count)
            let indicatorWidth = max(itemWidth - 12, 36)
            let indicatorX = CGFloat(selectedIndex) * itemWidth + (itemWidth - indicatorWidth) / 2

            ZStack(alignment: .leading) {
                barBackground
                    .frame(width: totalWidth, height: barHeight)

                slidingIndicator
                    .frame(width: indicatorWidth, height: indicatorHeight)
                    .offset(x: indicatorX)
                    .animation(.spring(response: 0.34, dampingFraction: 0.78), value: selectedTab)

                HStack(spacing: 0) {
                    ForEach(tabs, id: \.self) { tab in
                        tabButton(for: tab)
                            .frame(width: itemWidth, height: barHeight)
                    }
                }
            }
            .frame(width: totalWidth, height: barHeight)
        }
        .frame(height: barHeight)
    }

    private func tabButton(for tab: MainTab) -> some View {
        let isSelected = selectedTab == tab

        return Button {
            if selectedTab != tab {
                selectedTab = tab
            }
        } label: {
            Image(systemName: tab.symbol)
                .font(.system(size: tab == .post ? 22 : 18, weight: .bold))
                .foregroundStyle(isSelected ? hotPink : Color.white.opacity(0.62))
                .shadow(color: isSelected ? hotPink.opacity(0.55) : .clear, radius: 6, x: 0, y: 0)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var barBackground: some View {
        ZStack {
            Capsule()
                .fill(.ultraThinMaterial)

            Capsule()
                .fill(
                    LinearGradient(
                        colors: [tintTop, tintBottom],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
        }
        .overlay(
            Capsule()
                .stroke(Color.white.opacity(0.22), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.32), radius: 14, x: 0, y: 6)
    }

    private var slidingIndicator: some View {
        ZStack {
            Capsule()
                .fill(.ultraThinMaterial)

            Capsule()
                .fill(hotPink.opacity(0.30))
        }
        .overlay(
            Capsule()
                .stroke(Color.white.opacity(0.45), lineWidth: 1)
        )
        .shadow(color: hotPink.opacity(0.55), radius: 10, x: 0, y: 0)
    }
}

#Preview {
    ZStack {
        Image("JBIBackground")
            .resizable()
            .scaledToFill()
            .ignoresSafeArea()

        VStack {
            Spacer()
            MainTabBar(selectedTab: .constant(.feed))
                .padding(.horizontal, 18)
                .padding(.bottom, 24)
        }
    }
}
