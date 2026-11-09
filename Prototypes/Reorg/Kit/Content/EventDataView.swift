import SwiftUI

struct EventDataView: View {

    var body: some View {
        List {
            Section {
                LabeledContent("Catalog", value: "C107 · 412 MB")
                LabeledContent("Circle Cuts", value: "1.2 GB")
                LabeledContent("Maps", value: "38 MB")
            }
            Section {
                Button("Check for Updates") {}
                Button("Delete Event Data", role: .destructive) {}
            }
        }
        .navigationTitle("Event Data")
    }
}
