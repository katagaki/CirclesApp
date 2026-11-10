import SwiftUI

struct LauncherSection<Content: View>: View {

    let title: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10.0) {
            Text(title)
                .font(.headline)
                .foregroundStyle(.secondary)
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150.0), spacing: 10.0)], spacing: 10.0) {
                content()
            }
        }
    }
}
