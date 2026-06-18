import SwiftUI

enum JBITheme {
    static let darkBlue = Color(red: 1.0 / 255.0, green: 58.0 / 255.0, blue: 99.0 / 255.0)
    static let lightBlue = Color(red: 137.0 / 255.0, green: 194.0 / 255.0, blue: 217.0 / 255.0)
}

extension Color {
    static func jbiAccent(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? JBITheme.lightBlue : JBITheme.darkBlue
    }
}
