import SwiftUI

struct HubBuysView: View {

    @Environment(Harness.self) var harness

    var body: some View {
        List {
            Section {
                BuysTotalsHeader()
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
            }
            Section {
                HubSharedHeader()
            }
            Section("Shopping List") {
                ForEach(harness.buys) { item in
                    BuyRow(item: item)
                }
                Button("Add Item", systemImage: "plus") {}
            }
        }
    }
}
