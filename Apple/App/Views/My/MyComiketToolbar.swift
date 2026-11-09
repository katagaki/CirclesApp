import SwiftUI

struct MyComiketToolbar: ToolbarContent {

    @Environment(\.dismiss) var dismiss

    var body: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button(role: .close) {
                dismiss()
            }
        }
    }
}
