import SwiftUI

extension Color {
    static let onboardingHeroBackground = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark ? .black : .systemGroupedBackground
    })
}
