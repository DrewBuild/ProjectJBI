import SwiftUI

struct StatsView: View {
    let displayName: String
    let onSignedOut: () -> Void

    var body: some View {
        LoggedInPageView(displayName: displayName, section: "stats", onSignedOut: onSignedOut)
    }
}

#Preview {
    StatsView(displayName: "Drew J.", onSignedOut: {})
}
