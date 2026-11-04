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
            if let buyEntry {
                ForEach(buyEntry.items) { item in
                    readOnlyItemRow(item: item)
                }
            }
            if sharedBuys.isActive {
                ForEach(sharedBuys.items.filter { $0.circleID == circle.id }) { item in
                    SharedBuyItemRow(item: item) { sharedAssigningItem = item }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                sharedBuys.remove(itemID: item.id, circleID: item.circleID)
                            } label: {
                                Label("Shared.Delete", systemImage: "trash")
                            }
                        }
                }
            }
            if buyEntry?.items.isEmpty != false && !hasSharedItems {
                Button {
                    isEditingBuys = true
                } label: {
                    Label("Buys.AddItem", systemImage: "plus.circle.fill")
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

    var hasSharedItems: Bool {
        sharedBuys.isActive && sharedBuys.items.contains { $0.circleID == circle.id }
    }

    @ViewBuilder
    func readOnlyItemRow(item: BuyItem) -> some View {
        HStack(spacing: 8.0) {
            buyItemThumbnail(item: item)
                .overlay {
                    if item.status == .bought {
                        Color.black.opacity(0.3)
                            .clipShape(RoundedRectangle(cornerRadius: 6.0))
                        Circle()
                            .fill(Color.accentColor)
                            .frame(width: 20.0, height: 20.0)
                            .overlay {
                                Circle()
                                    .strokeBorder(.white, lineWidth: 1.5)
                                Image(systemName: "checkmark")
                                    .font(.system(size: 10.0, weight: .bold))
                                    .foregroundStyle(.white)
                            }
                            .shadow(color: .black.opacity(0.3), radius: 2.0, y: 1.0)
                    }
                }
                .onTapGesture {
                    if let imageData = item.imageData, let image = UIImage(data: imageData) {
                        buysViewerImage = image
                    }
                }
            Button {
                var updated = item
                updated.status = item.status.next
                BuysDatabase.shared.updateItem(updated, eventNumber: planner.activeEventNumber)
                withAnimation(.smooth.speed(2.0)) {
                    reloadEntry()
                }
            } label: {
                HStack(spacing: 8.0) {
                    Text(item.name)
                        .strikethrough(item.status == .cancelled)
                        .foregroundStyle(item.status != .pending ? .secondary : .primary)
                    Spacer()
                    Text("Buys.CostValue.\(item.cost)")
                        .foregroundStyle(.secondary)
                        .strikethrough(item.status == .cancelled)
                        .monospacedDigit()
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }

    @ViewBuilder
    func buyItemThumbnail(item: BuyItem) -> some View {
        if let imageData = item.imageData, let uiImage = UIImage(data: imageData) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
                .frame(width: 36.0, height: 36.0)
                .clipShape(RoundedRectangle(cornerRadius: 6.0))
        } else {
            Image(systemName: "photo")
                .font(.system(size: 14.0))
                .foregroundStyle(.secondary)
                .frame(width: 36.0, height: 36.0)
                .background(Color(.systemGray5))
                .clipShape(RoundedRectangle(cornerRadius: 6.0))
        }
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
