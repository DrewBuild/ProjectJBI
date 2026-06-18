import SwiftUI

private enum PostFlowStep {
    case chooseLocation
    case details
}

struct PostView: View {
    let displayName: String
    let onSignedOut: () -> Void
    var onPostCreated: () -> Void = {}

    @Environment(\.colorScheme) private var colorScheme
    @State private var mode: PostMode = .location
    @State private var step: PostFlowStep = .chooseLocation
    @State private var draft = CreatePostInput(mode: .location)
    @State private var showNotifications = false
    @State private var showFriendSearch = false
    @State private var showMenu = false
    @State private var isSigningOut = false
    @State private var errorText: String?
    @State private var navigationPath: [UUID] = []
    @AppStorage("appColorScheme") private var appColorScheme = "system"
    @AppStorage("useLocationForPosts") private var useLocationForPosts = true

    private var foregroundColor: Color {
        colorScheme == .dark ? .white : .black
    }

    var body: some View {
        NavigationStack(path: $navigationPath) {
            GeometryReader { geometry in
                let headerHeight = geometry.safeAreaInsets.top + 42

                ZStack(alignment: .top) {
                    AppScreenBackground()

                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            Color.clear
                                .frame(height: headerHeight + 16)

                            if step == .chooseLocation {
                                firstStep
                            } else {
                                CreatePostDetailsView(startingInput: draft) {
                                    resetFlow()
                                    onPostCreated()
                                }
                            }

                            if let errorText {
                                Text(errorText)
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundStyle(.red.opacity(0.9))
                                    .frame(maxWidth: .infinity)
                            }

                            Spacer(minLength: 100)
                        }
                        .padding(.horizontal, 18)
                    }
                    .scrollContentBackground(.hidden)
                    .refreshable {
                        await refresh()
                    }

                    MainHeaderView(
                        displayName: displayName,
                        section: "post",
                        onNotifications: { showNotifications = true },
                        onFindFriends: { showFriendSearch = true },
                        onMenu: { withAnimation(.easeInOut(duration: 0.18)) { showMenu.toggle() } }
                    )
                    .frame(height: headerHeight)
                    .zIndex(1)

                    if showMenu {
                        MainMenuOverlay(
                            isSigningOut: isSigningOut,
                            onToggleAppearance: toggleAppearance,
                            onSignOut: signOut,
                            onDismiss: { withAnimation(.easeInOut(duration: 0.18)) { showMenu = false } }
                        )
                        .zIndex(2)
                    }
                }
                .sheet(isPresented: $showNotifications) {
                    NotificationView(displayName: displayName)
                }
                .sheet(isPresented: $showFriendSearch) {
                    FriendSearchView { selected in
                        navigationPath.append(selected.id)
                    }
                }
                .navigationDestination(for: UUID.self) { id in
                    ProfileView(profileId: id, onSignedOut: onSignedOut, ownsNavigationStack: false)
                }
                .onAppear {
                    if step == .chooseLocation {
                        mode = useLocationForPosts ? .location : .manual
                        draft.mode = mode
                    }
                }
                .onChange(of: mode) { _, newMode in
                    draft.mode = newMode
                    errorText = nil
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    private var firstStep: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Where did you get coffee?")
                .font(.system(size: 28, weight: .heavy))
                .foregroundStyle(foregroundColor)

            Picker("Post mode", selection: $mode) {
                ForEach(PostMode.allCases) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .tint(Color.jbiAccent(for: colorScheme))

            if mode == .location {
                CoffeeShopMapPickerView { shop in
                    draft.selectedShop = shop
                    draft.mode = .location
                    withAnimation(.easeInOut(duration: 0.18)) {
                        step = .details
                    }
                }
            } else {
                manualEntry
            }
        }
    }

    private var manualEntry: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Manual posts do not count as verified location reviews.")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(foregroundColor.opacity(0.62))

            labeledField("Coffee shop name", text: $draft.manualShopName, placeholder: "Just Bean It Cafe")
            labeledField("City", text: $draft.manualCity, placeholder: "Hoboken")
            labeledField("State", text: $draft.manualState, placeholder: "NJ")
            labeledField("Optional address", text: $draft.manualAddress, placeholder: "123 Coffee St")

            Button {
                continueManual()
            } label: {
                Text("Continue")
                    .font(.system(size: 16, weight: .heavy))
                    .foregroundStyle(canContinueManual ? (colorScheme == .dark ? JBITheme.darkBlue : .white) : foregroundColor.opacity(0.45))
                    .frame(maxWidth: .infinity)
                    .frame(height: 46)
                    .background(Color.jbiAccent(for: colorScheme).opacity(canContinueManual ? 1 : 0.24))
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .disabled(!canContinueManual)
        }
    }

    private var canContinueManual: Bool {
        !draft.manualShopName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func labeledField(_ label: String, text: Binding<String>, placeholder: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 13, weight: .heavy))
                .foregroundStyle(foregroundColor)
            TextField(placeholder, text: text)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(foregroundColor)
                .tint(Color.jbiAccent(for: colorScheme))
                .padding(.horizontal, 12)
                .frame(height: 44)
                .background(foregroundColor.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
    }

    private func continueManual() {
        guard canContinueManual else { return }
        draft.mode = .manual
        withAnimation(.easeInOut(duration: 0.18)) {
            step = .details
        }
    }

    private func resetFlow() {
        draft = CreatePostInput(mode: useLocationForPosts ? .location : .manual)
        mode = draft.mode
        step = .chooseLocation
    }

    private func refresh() async {}

    private func toggleAppearance() {
        appColorScheme = appColorScheme == "dark" ? "light" : "dark"
        withAnimation(.easeInOut(duration: 0.18)) {
            showMenu = false
        }
    }

    private func signOut() {
        guard !isSigningOut else { return }
        isSigningOut = true
        errorText = nil

        Task {
            do {
                try await AuthService().signOut()
                await MainActor.run {
                    isSigningOut = false
                    onSignedOut()
                }
            } catch {
                print("PostView signOut failed:", error)
                await MainActor.run {
                    isSigningOut = false
                    showMenu = false
                    errorText = "Could not log out. Try again."
                }
            }
        }
    }
}

#Preview {
    PostView(displayName: "Drew J.", onSignedOut: {})
}
