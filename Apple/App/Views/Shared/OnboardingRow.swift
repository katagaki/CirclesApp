import SwiftUI

struct OnboardingRow<Icon: View>: View {

    let icon: Icon
    let title: LocalizedStringKey
    let message: LocalizedStringKey

    init(title: LocalizedStringKey, message: LocalizedStringKey, @ViewBuilder icon: () -> Icon) {
        self.icon = icon()
        self.title = title
        self.message = message
    }

    var body: some View {
        HStack(alignment: .top, spacing: 16.0) {
            icon
                .frame(width: 36.0)
            VStack(alignment: .leading, spacing: 3.0) {
                Text(title)
                    .font(.headline)
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
