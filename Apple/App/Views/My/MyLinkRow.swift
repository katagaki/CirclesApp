import SwiftUI

struct MyLinkRow: View {

    let url: String
    let title: LocalizedStringKey
    let image: String

    var body: some View {
        Link(destination: URL(string: url)!) {
            HStack {
                ListIconLabel(title: title, image: image)
                Spacer()
                Image(systemName: "safari")
                    .foregroundStyle(.foreground.opacity(0.5))
            }
        }
        .tint(.primary)
    }
}
