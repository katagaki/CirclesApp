import SwiftUI

struct GoCard<Content: View>: View {

    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 14.0) {
            content()
        }
        .padding(14.0)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(uiColor: .secondarySystemGroupedBackground), in: .rect(cornerRadius: 18.0))
    }
}
