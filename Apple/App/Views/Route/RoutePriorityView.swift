import RADiUS
import SwiftUI

/// Every favourite colour as a circle. Tapping one includes or leaves it out; dragging one
/// onto another moves it there. Included colours are numbered in the order they are visited.
struct RoutePriorityView: View {

    @Environment(Navigator.self) var navigator
    @Environment(Unifier.self) var unifier

    @AppStorage(wrappedValue: "", "Route.ColorPriority") var storedOrder: String
    @AppStorage(wrappedValue: "", "Route.ColorExcluded") var storedExcluded: String

    @State var order: [WebCatalogColor] = []
    @State var included: Set<WebCatalogColor> = []
    @State var dragging: WebCatalogColor?

    let columns = [GridItem(.adaptive(minimum: 72.0, maximum: 96.0), spacing: 12.0)]

    var canStart: Bool {
        order.contains { included.contains($0) && (navigator.priorityCounts[$0] ?? 0) > 0 }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16.0) {
                Text("Route.Priority.Footer")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                LazyVGrid(columns: columns, spacing: 16.0) {
                    ForEach(order, id: \.self) { color in
                        RoutePriorityColorCell(
                            color: color,
                            rank: rank(of: color),
                            count: navigator.priorityCounts[color] ?? 0
                        )
                        .onTapGesture {
                            withAnimation(.smooth) {
                                if included.contains(color) {
                                    included.remove(color)
                                } else {
                                    included.insert(color)
                                }
                            }
                        }
                        .onDrag {
                            dragging = color
                            return NSItemProvider(object: String(color.rawValue) as NSString)
                        }
                        .onDrop(
                            of: [.text],
                            delegate: RoutePriorityDropDelegate(target: color, order: $order, dragging: $dragging)
                        )
                    }
                }
            }
            .padding(20.0)
        }
        .onDrop(of: [.text], isTargeted: nil) { _ in
            dragging = nil
            return true
        }
        .navigationTitle("Route.Priority.Title")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(role: .cancel) {
                    navigator.chosenPriority = nil
                    finish()
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button(role: .confirm) {
                    save()
                    navigator.chosenPriority = order.filter { included.contains($0) }
                    finish()
                }
                .disabled(!canStart)
            }
        }
        .navigationBarBackButtonHidden()
        .onAppear(perform: load)
    }

    func finish() {
        unifier.closeRouteScreen(.routePriority)
        navigator.priorityDismissals += 1
    }

    func rank(of color: WebCatalogColor) -> Int? {
        let checked = order.filter { included.contains($0) }
        return checked.firstIndex(of: color).map { $0 + 1 }
    }

    func load() {
        let saved = storedOrder.split(separator: ",").compactMap { Int($0) }
            .compactMap(WebCatalogColor.init(rawValue:))
            .filter { $0 != .uncolored }
        let rest = WebCatalogColor.assignable.filter { !saved.contains($0) }
        order = saved + rest
        if storedOrder.isEmpty {
            included = Set(order.filter { (navigator.priorityCounts[$0] ?? 0) > 0 })
        } else {
            let excluded = Set(storedExcluded.split(separator: ",").compactMap { Int($0) }
                .compactMap(WebCatalogColor.init(rawValue:)))
            included = Set(order).subtracting(excluded)
        }
    }

    func save() {
        storedOrder = order.map { String($0.rawValue) }.joined(separator: ",")
        storedExcluded = order.filter { !included.contains($0) }.map { String($0.rawValue) }.joined(separator: ",")
    }
}
