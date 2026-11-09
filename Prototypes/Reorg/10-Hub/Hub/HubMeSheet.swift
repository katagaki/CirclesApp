import SwiftUI

struct HubMeSheet: View {

    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            HubMeView()
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button(role: .close) { dismiss() }
                    }
                }
                .featureDestinations()
        }
        .presentationDetents([.large])
    }
}
