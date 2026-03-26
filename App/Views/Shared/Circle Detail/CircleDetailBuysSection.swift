//
//  CircleDetailBuysSection.swift
//  CiRCLES
//
//  Created by Claude on 2026/03/24.
//

import SwiftData
import SwiftUI
import AXiS

struct CircleDetailBuysSection: View {

    @Environment(\.modelContext) private var modelContext
    @Environment(Events.self) var planner

    let circle: ComiketCircle

    @Query var allBuyEntries: [CirclesBuyEntry]

    @State private var isEditing: Bool = false
    @State private var editingImageItemID: UUID?
    @State private var isImageFlowPresented: Bool = false

    var buyEntry: CirclesBuyEntry? {
        allBuyEntries.first {
            $0.circleID == circle.id && $0.eventNumber == planner.activeEventNumber
        }
    }

    var body: some View {
        Section {
            if let buyEntry, !buyEntry.items.isEmpty {
                ForEach(Array(buyEntry.items.enumerated()), id: \.element.id) { index, item in
                    if isEditing {
                        editableItemRow(buyEntry: buyEntry, index: index, item: item)
                    } else {
                        readOnlyItemRow(buyEntry: buyEntry, index: index, item: item)
                    }
                }
                .onMove { from, destination in
                    buyEntry.items.move(fromOffsets: from, toOffset: destination)
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
        .fullScreenCover(isPresented: $isImageFlowPresented) {
            ImagePickerFlowView(
                onComplete: { croppedImage in
                    applyImage(croppedImage)
                    isImageFlowPresented = false
                },
                onCancel: {
                    editingImageItemID = nil
                    isImageFlowPresented = false
                }
            )
        }
    }

    @ViewBuilder
    func readOnlyItemRow(buyEntry: CirclesBuyEntry, index: Int, item: CirclesBuyEntry.BuyItem) -> some View {
        Button {
            withAnimation(.smooth.speed(2.0)) {
                buyEntry.items[index].status = item.status.next
            }
        } label: {
            HStack(spacing: 8.0) {
                if let imageData = item.imageData, let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 36.0, height: 36.0)
                        .clipShape(RoundedRectangle(cornerRadius: 6.0))
                }
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

    @ViewBuilder
    func editableItemRow(buyEntry: CirclesBuyEntry, index: Int, item: CirclesBuyEntry.BuyItem) -> some View {
        HStack(spacing: 8.0) {
            if let imageData = item.imageData, let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 36.0, height: 36.0)
                    .clipShape(RoundedRectangle(cornerRadius: 6.0))
            }
            TextField("Buys.ItemName.Placeholder", text: Binding(
                get: { item.name },
                set: { newValue in
                    buyEntry.items[index].name = newValue
                }
            ))
            TextField("Buys.ItemCost.Placeholder", text: Binding(
                get: { item.cost == 0 && item.name.isEmpty ? "" : String(item.cost) },
                set: { newValue in
                    buyEntry.items[index].cost = Int(newValue) ?? 0
                }
            ))
            .keyboardType(.numberPad)
            .frame(width: 70.0)
            .multilineTextAlignment(.trailing)
            .foregroundStyle(.secondary)
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                deleteItem(at: index)
            } label: {
                Label("Shared.Delete", systemImage: "trash")
            }
            Button {
                editingImageItemID = item.id
                isImageFlowPresented = true
            } label: {
                Label("Buys.SelectImage", systemImage: "photo")
            }
            .tint(.blue)
        }
    }

    func addBlankItem() {
        let newItem = CirclesBuyEntry.BuyItem(name: "", cost: 0)
        if let buyEntry {
            buyEntry.items.append(newItem)
        } else {
            let entry = CirclesBuyEntry(
                circleID: circle.id,
                eventNumber: planner.activeEventNumber,
                items: [newItem]
            )
            modelContext.insert(entry)
        }
    }

    func deleteItem(at index: Int) {
        guard let buyEntry else { return }
        buyEntry.items.remove(at: index)
        if buyEntry.items.isEmpty {
            modelContext.delete(buyEntry)
        }
    }

    func applyImage(_ image: UIImage) {
        guard let buyEntry, let itemID = editingImageItemID else {
            editingImageItemID = nil
            return
        }
        if let index = buyEntry.items.firstIndex(where: { $0.id == itemID }) {
            buyEntry.items[index].imageData = image.jpegData(compressionQuality: 0.7)
        }
        editingImageItemID = nil
    }
}
