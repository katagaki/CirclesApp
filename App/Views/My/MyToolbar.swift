import SwiftUI

struct MyToolbar: ToolbarContent {
    @Environment(\.dismiss) var dismiss

    @Binding var eventTitle: String?
    @Binding var eventCoverImage: UIImage?
    @Binding var isShowingEventCoverImage: Bool

    var body: some ToolbarContent {
        if eventCoverImage != nil, UIDevice.current.userInterfaceIdiom != .pad {
            ToolbarItem(placement: .primaryAction) {
                Button(eventTitle ?? String(localized: "ViewTitle.My"), systemImage: "photo") {
                    withAnimation(.smooth.speed(2.0)) {
                        isShowingEventCoverImage.toggle()
                    }
                }
            }
        }
        ToolbarItem(placement: .topBarLeading) {
            Button(role: .close) {
                dismiss()
            }
        }
    }
}
