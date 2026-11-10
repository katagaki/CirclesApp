import Foundation
import SwiftUI

struct InfoStackSection: View {
    let title: String
    let contents: String
    let canTranslate: Bool
    let showContextMenu: Bool

    init(title: String, contents: String, canTranslate: Bool, showContextMenu: Bool = true) {
        self.title = title
        self.contents = contents
        self.canTranslate = canTranslate
        self.showContextMenu = showContextMenu
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4.0) {
            Group {
                Text(LocalizedStringKey(title))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)

                if showContextMenu {
                    TranslatableText(contents, canTranslate: canTranslate)
                        .font(.subheadline)
                } else {
                    Text(contents)
                        .font(.subheadline)
                        .textSelection(.enabled)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
