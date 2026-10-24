import AXiS
import ORBiT
import SwiftUI

struct CircleDetailBuysSection: View {

    @Environment(Events.self) var planner
    @Environment(SharedBuysSession.self) var sharedBuys

    let circle: ComiketCircle

    @State private var buyEntry: BuyEntry?
    @State private var isEditing: Bool = false
    @State private var sharedDrafts: [SharedBuyDraft] = []

    @Binding var buysAttachmentPickerCircle: ComiketCircle?
    @Binding var buysCropImage: UIImage?
    @Binding var buysCropItemID: String?
    @Binding var buysViewerImage: UIImage?

    var body: some View {
        Section {
            if let buyEntry, !buyEntry.items.isEmpty {
                ForEach(Array(buyEntry.items.enumerated()), id: \.element.id) { index, item in
                    if isEditing {
                        editableItemRow(index: index, item: item)
                    } else {
                        readOnlyItemRow(item: item)
                    }
                }
                .onMove { from, destination in
                    BuysDatabase.shared.moveItems(
                        circleID: circle.id,
                        eventNumber: planner.activeEventNumber,
                        fromOffsets: from,
                        toOffset: destination
                    )
                    reloadEntry()
                }
                .moveDisabled(!isEditing)
            }
            ForEach($sharedDrafts) { $draft in
                SharedBuyDraftRow(
                    circleID: circle.id,
                    circleName: circle.circleName,
                    circleSpace: circle.spaceName(),
                    itemID: $draft.itemID
                )
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            discardDraft(draft)
                        } label: {
                            Label("Shared.Delete", systemImage: "trash")
                        }
                    }
            }
            if isEditing || buyEntry == nil || buyEntry?.items.isEmpty == true {
                Button {
                    if !isEditing {
                        isEditing = true
                    }
                    addBlankItem()
                } label: {
                    Label("Buys.AddItem", systemImage: "plus.circle.fill")
                }
                if sharedBuys.isActive {
                    Button {
                        sharedDrafts.append(SharedBuyDraft())
                    } label: {
                        Label("Buys.AddItem.Shared", systemImage: "person.2.badge.plus")
                    }
                }
            }
        } header: {
            HStack {
                Text("Buys.Section.Title")
                Spacer()
                Button {
                    isEditing.toggle()
                } label: {
                    Text(isEditing ? "Shared.Done" : "Shared.Edit")
                        .font(.subheadline)
                        .textCase(nil)
                }
            }
        }
        .onAppear {
            reloadEntry()
        }
        .onChange(of: buysCropImage) {
            if buysCropImage == nil && buysCropItemID == nil {
                reloadEntry()
            }
        }
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
    func editableItemRow(index: Int, item: BuyItem) -> some View {
        HStack(spacing: 8.0) {
            buyItemThumbnail(item: item)
                .onTapGesture {
                    selectImageFromAttachments(for: item.id)
                }
            TextField("Buys.ItemName.Placeholder", text: Binding(
                get: { item.name },
                set: { newValue in
                    var updated = item
                    updated.name = newValue
                    BuysDatabase.shared.updateItem(updated, eventNumber: planner.activeEventNumber)
                    reloadEntry()
                }
            ))
            TextField("Buys.ItemCost.Placeholder", text: Binding(
                get: { item.cost == 0 && item.name.isEmpty ? "" : String(item.cost) },
                set: { newValue in
                    var updated = item
                    updated.cost = Int(newValue) ?? 0
                    BuysDatabase.shared.updateItem(updated, eventNumber: planner.activeEventNumber)
                    reloadEntry()
                }
            ))
            .keyboardType(.numberPad)
            .frame(width: 70.0)
            .multilineTextAlignment(.trailing)
            .foregroundStyle(.secondary)
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                deleteItem(id: item.id)
            } label: {
                Label("Shared.Delete", systemImage: "trash")
            }
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

    func selectImageFromAttachments(for itemID: String) {
        let attachments = AttachmentsDatabase.shared.attachments(
            eventNumber: circle.eventNumber,
            circleID: circle.id
        )
        buysCropItemID = itemID
        if attachments.count == 1,
           let image = UIImage(data: attachments[0].attachmentBlob) {
            buysCropImage = image
        } else {
            buysAttachmentPickerCircle = circle
        }
    }

    func discardDraft(_ draft: SharedBuyDraft) {
        if let itemID = draft.itemID {
            sharedBuys.remove(itemID: itemID, circleID: circle.id)
        }
        sharedDrafts.removeAll { $0.id == draft.id }
    }

    func addBlankItem() {
        let newItem = BuyItem(name: "", cost: 0)
        BuysDatabase.shared.addItem(newItem, circleID: circle.id, eventNumber: planner.activeEventNumber)
        reloadEntry()
    }

    func deleteItem(id: String) {
        BuysDatabase.shared.deleteItem(id: id, eventNumber: planner.activeEventNumber)
        reloadEntry()
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

struct SharedBuyDraft: Identifiable {
    let id = UUID()
    var itemID: String?
}
