import Foundation
import SwiftUI

struct ListSectionWithTranslateButton: View {
    var title: String
    var text: String
    var showContextMenu: Bool

    init(title: String, text: String, showContextMenu: Bool = true) {
        self.title = title
        self.text = text
        self.showContextMenu = showContextMenu
    }

    var body: some View {
        Section {
            if showContextMenu {
                TranslatableText(text)
            } else {
                Text(text)
                    .textSelection(.enabled)
            }
        } header: {
            Text(LocalizedStringKey(title))
        }
    }
}
