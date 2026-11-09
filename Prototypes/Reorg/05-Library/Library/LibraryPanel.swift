import SwiftUI

struct LibraryPanel: View {

    @Environment(\.stageStyle) var stageStyle
    @Environment(\.stageSize) var stageSize
    @Binding var detent: PresentationDetent

    var body: some View {
        if stageStyle == .panel && stageSize.width * 0.48 >= 520.0 {
            LibrarySplitPanel()
        } else {
            LibraryStackPanel(detent: $detent)
        }
    }
}
