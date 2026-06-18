import SwiftUI

struct NotificationView: View {
    let displayName: String

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    private var foregroundColor: Color {
        colorScheme == .dark ? .white : .black
    }

    private var headerBackground: Color {
        colorScheme == .dark ? Color.black.opacity(0.72) : Color.white.opacity(0.72)
    }

    private var dividerColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.10) : Color.black.opacity(0.08)
    }

    var body: some View {
        GeometryReader { geometry in
            let headerHeight = geometry.safeAreaInsets.top + 42

            ZStack(alignment: .top) {
                AppScreenBackground()

                ScrollView {
                    VStack(spacing: 0) {
                        Color.clear
                            .frame(height: headerHeight + 16)

                        Text("No notifications yet.")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(foregroundColor.opacity(0.62))
                            .frame(maxWidth: .infinity)
                            .padding(.top, 54)

                        Spacer(minLength: 600)
                    }
                }
                .scrollContentBackground(.hidden)
                .refreshable {
                    await refreshNotifications()
                }

                ZStack(alignment: .bottom) {
                    Rectangle()
                        .fill(.ultraThinMaterial)
                        .overlay(headerBackground)
                        .ignoresSafeArea(edges: .top)

                    Rectangle()
                        .fill(dividerColor)
                        .frame(height: 1)

                    ZStack {
                        Text("\(displayName) | notifications")
                            .font(.system(size: 13, weight: .heavy))
                            .foregroundStyle(foregroundColor)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                            .padding(.horizontal, 72)

                        HStack {
                            Spacer()
                            Button("Done") { dismiss() }
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(foregroundColor)
                                .frame(height: 44)
                        }
                        .padding(.horizontal, 18)
                    }
                    .padding(.top, geometry.safeAreaInsets.top + 4)
                    .frame(height: headerHeight, alignment: .top)
                }
                .frame(height: headerHeight)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    private func refreshNotifications() async {}
}

#Preview {
    NotificationView(displayName: "Drew J.")
}
