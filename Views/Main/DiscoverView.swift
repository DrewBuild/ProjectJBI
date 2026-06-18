import SwiftUI

struct DiscoverView: View {
    let displayName: String
    let onSignedOut: () -> Void

    var body: some View {
        LoggedInPageView(displayName: displayName, section: "discover", onSignedOut: onSignedOut)
    }
}

#Preview {
    DiscoverView(displayName: "Drew J.", onSignedOut: {})
}
