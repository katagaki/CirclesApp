import SwiftUI

struct LoginFeatureHero: View {
    var icon: LoginHeroIcon.Kind
    var title: LocalizedStringKey
    var description: LocalizedStringKey

    var body: some View {
        HStack(alignment: .center, spacing: 16.0) {
            LoginHeroIcon(kind: icon)
            VStack(alignment: .leading, spacing: 6.0) {
                Text(title)
                    .fontWeight(.bold)
                Text(description)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0.0)
        }
    }
}
