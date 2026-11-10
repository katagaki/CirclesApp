import SwiftUI

struct BuysView: View {

    @Environment(Harness.self) var harness
    var showsSharedSection: Bool = true

    var body: some View {
        List {
            Section {
                BuysTotalsHeader()
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 0.0, leading: 0.0, bottom: 0.0, trailing: 0.0))
            }
            if showsSharedSection {
                Section {
                    SharedBuysEntryRow()
                }
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
