import AXiS
import ORBiT
import SwiftUI

struct CircleDetailBuysSection: View {

    @Environment(Events.self) var planner
    @Environment(SharedBuysSession.self) var sharedBuys

    let circle: ComiketCircle

    @State private var buyEntry: BuyEntry?

    @Binding var buysViewerImage: UIImage?
    @Binding var isEditingBuys: Bool
    @Binding var sharedAssigningItem: SharedBuyItem?

    var body: some View {
        Section {
            if items.isEmpty && sharedItems.isEmpty {
                Button {
                    isEditingBuys = true
                } label: {
                    Label("Buys.AddItem", systemImage: "plus.circle.fill")
                }
            } else {
                BuyItemGrid {
                    ForEach(items) { item in
                        MyBuyItemTile(item: item, expandedImage: $buysViewerImage, onReload: reloadEntry)
                    }
                    ForEach(sharedItems) { item in
                        SharedBuyItemTile(
                            item: item,
                            onAssign: { sharedAssigningItem = item },
                            onViewPhoto: { buysViewerImage = $0 }
                        )
                        .contextMenu {
                            Button("Shared.Delete", systemImage: "trash", role: .destructive) {
                                sharedBuys.remove(itemID: item.id, circleID: item.circleID)
                            }
                        }
                    }
                }
            }
        } header: {
            HStack {
                Text("Buys.Section.Title")
                Spacer()
                Button {
                    isEditingBuys = true
                } label: {
                    Text("Shared.Edit")
                        .font(.subheadline)
                        .textCase(nil)
                }
            }
        }
        .onAppear {
            reloadEntry()
        }
        .onChange(of: isEditingBuys) {
            reloadEntry()
        }
    }

    var items: [BuyItem] {
        buyEntry?.items ?? []
    }

    var sharedItems: [SharedBuyItem] {
        sharedBuys.isActive ? sharedBuys.items.filter { $0.circleID == circle.id } : []
    }

    func reloadEntry() {
        buyEntry = BuysDatabase.shared.entry(for: circle.id, eventNumber: planner.activeEventNumber)
    }
}

struct BuyImageViewerItem: Identifiable {
    let id = UUID()
    let image: UIImage
}

struct BuyImageViewer: View {

    @Environment(\.dismiss) var dismiss

    let image: UIImage

    @State var currentScale: CGFloat = 1.0
    @State var anchor: UnitPoint = .center

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .scaleEffect(currentScale, anchor: anchor)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .gesture(
                        MagnifyGesture()
                            .onChanged { value in
                                currentScale = value.magnification
                                anchor = value.startAnchor
                            }
                            .onEnded { _ in
                                withAnimation(.smooth.speed(2.0)) {
                                    currentScale = 1.0
                                }
                            }
                    )
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Shared.Back", systemImage: "chevron.left") {
                        dismiss()
                    }
                }
            }
        }
    }
}
