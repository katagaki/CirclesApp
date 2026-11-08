import RADiUS
import SwiftUI

/// Lets the visitor rank their favourite colours. Checked colours are visited from the top
/// down; the order is remembered for next time.
struct RoutePriorityView: View {

    @Environment(\.dismiss) var dismiss
    @Environment(Navigator.self) var navigator

    @AppStorage(wrappedValue: "", "Route.ColorPriority") var storedOrder: String
    @AppStorage(wrappedValue: "", "Route.ColorExcluded") var storedExcluded: String

    @State var order: [WebCatalogColor] = []
    @State var included: Set<WebCatalogColor> = []

    var body: some View {
        NavigationStack {
            List(selection: $included) {
                Section {
                    ForEach(order, id: \.self) { color in
                        RoutePriorityRow(
                            color: color,
                            rank: rank(of: color),
                            count: navigator.priorityCounts[color] ?? 0
                        )
                        .tag(color)
                    }
                    .onMove { source, destination in
                        order.move(fromOffsets: source, toOffset: destination)
                    }
                } footer: {
                    Text("Route.Priority.Footer")
                }
            }
            .environment(\.editMode, .constant(.active))
            .navigationTitle("Route.Priority.Title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(role: .cancel) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(role: .confirm) {
                        save()
                        navigator.chosenPriority = order.filter { included.contains($0) }
                        dismiss()
                    }
                    .disabled(included.isEmpty)
                }
            }
        }
        .onAppear(perform: load)
    }

    func rank(of color: WebCatalogColor) -> Int? {
        let checked = order.filter { included.contains($0) }
        return checked.firstIndex(of: color).map { $0 + 1 }
    }

    func load() {
        let saved = storedOrder.split(separator: ",").compactMap { Int($0) }.compactMap(WebCatalogColor.init(rawValue:))
        let excluded = Set(storedExcluded.split(separator: ",").compactMap { Int($0) }.compactMap(WebCatalogColor.init(rawValue:)))
        let present = Set(navigator.priorityCounts.keys)
        let known = saved.filter { present.contains($0) }
        let rest = present.subtracting(known).sorted { $0.rawValue < $1.rawValue }
        order = known + rest
        included = present.subtracting(excluded)
    }

    func save() {
        let previous = storedOrder.split(separator: ",").compactMap { Int($0) }
        let shown = order.map(\.rawValue)
        storedOrder = (shown + previous.filter { !shown.contains($0) }).map(String.init).joined(separator: ",")
        let excluded = order.filter { !included.contains($0) }.map(\.rawValue)
        storedExcluded = excluded.map(String.init).joined(separator: ",")
    }
}
