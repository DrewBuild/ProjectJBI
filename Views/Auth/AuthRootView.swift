import SwiftUI

struct AuthRootView: View {
    @State private var isAuthenticated = false
    @State private var isCheckingSession = true

    var body: some View {
        Group {
            if isCheckingSession {
                LoadingView()
            } else if isAuthenticated {
                TemporaryHomeView {
                    isAuthenticated = false
                }
            } else {
                StartScreenView {
                    isAuthenticated = true
                }
            }
        }
        .ignoresSafeArea()
        .task {
            isAuthenticated = await AuthService().hasCurrentSession()
            isCheckingSession = false
        }
    }

}

#Preview {
    AuthRootView()
}
