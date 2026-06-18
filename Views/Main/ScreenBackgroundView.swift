import SwiftUI

extension Notification.Name {
    static let jbiRevealTabBar = Notification.Name("JBIRevealTabBar")
}

struct AppScreenBackground: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Group {
            if colorScheme == .dark {
                Color.black
            } else {
                Color.white
            }
        }
        .ignoresSafeArea()
    }
}

struct MainHeaderView: View {
    let displayName: String
    let section: String

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Text("\(displayName) | \(section)")
            .font(.system(size: 13, weight: .heavy))
            .foregroundStyle(colorScheme == .dark ? Color.white : Color.black)
            .opacity(0.9)
            .frame(maxWidth: .infinity, alignment: .center)
    }
}

#Preview {
    AppScreenBackground()
}
