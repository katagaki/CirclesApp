//
//  CircleDetailBuysSection.swift
//  CiRCLES
//
//  Created by Claude on 2026/03/24.
//

import SwiftUI
import AXiS

struct CircleDetailBuysSection: View {

    @Environment(Events.self) var planner

    let circle: ComiketCircle

    @State private var buyEntry: BuyEntry?
    @State private var isEditing: Bool = false

    @Binding var buysAttachmentPickerCircle: ComiketCircle?
    @Binding var buysCropImage: UIImage?
    @Binding var buysCropItemID: String?

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
            if isEditing || buyEntry == nil || buyEntry?.items.isEmpty == true {
                Button {
                    if !isEditing {
                        isEditing = true
                    }
                    addBlankItem()
                } label: {
                    Label("Buys.AddItem", systemImage: "plus.circle.fill")
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
            // When crop image is cleared after a crop completes, reload
            if buysCropImage == nil && buysCropItemID == nil {
                reloadEntry()
            }
        }
    }

    @ViewBuilder
    func readOnlyItemRow(item: BuyItem) -> some View {
        HStack(spacing: 8.0) {
            buyItemThumbnail(item: item)
                .onTapGesture {
                    selectImageFromAttachments(for: item.id)
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
                        .foregroundStyle(item.status == .cancelled ? .secondary : .primary)
                    Spacer()
                    Text("Buys.CostValue.\(item.cost)")
                        .foregroundStyle(.secondary)
                        .strikethrough(item.status == .cancelled)
                        .monospacedDigit()
                    if item.status == .bought {
                        Image(systemName: "checkmark")
                            .foregroundStyle(.green)
                    }
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
            Button(role: .destructive) {
                deleteItem(id: item.id)
            } label: {
                Image(systemName: "trash")
                    .font(.caption)
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
