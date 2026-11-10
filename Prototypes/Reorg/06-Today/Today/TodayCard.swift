import SwiftUI

struct TodayCard<Content: View>: View {

    let title: String
    let symbol: String
    let tint: Color
    let destination: Feature
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10.0) {
            HStack(spacing: 6.0) {
                Image(systemName: symbol)
                Text(title.uppercased())
                Spacer(minLength: 8.0)
                NavigationLink("See All", value: destination)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color.accentColor)
            }
            .font(.caption.weight(.bold))
            .foregroundStyle(tint)
            content()
        }
        .padding(14.0)
        .background(.fill.quaternary, in: .rect(cornerRadius: 20.0))
    }
}
