import SwiftUI

private let sourceCodeURL = "https://github.com/katagaki/CirclesApp"

struct MyAboutSection: View {

    var body: some View {
        Section {
            Link(destination: URL(string: sourceCodeURL)!) {
                HStack {
                    Text("More.GitHub")
                    Spacer()
                    Text(verbatim: "katagaki/CirclesApp")
                        .foregroundStyle(.secondary)
                }
            }
            .tint(.primary)
            NavigationLink(value: MyComiketPath.attributions) {
                Text("More.Attributions")
            }
        } footer: {
            Text("More.Disclaimer")
        }
    }
}
