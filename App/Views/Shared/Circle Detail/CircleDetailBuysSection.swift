//
//  CircleDetailBuysSection.swift
//  CiRCLES
//
//  Created by Claude on 2026/03/24.
//

import PhotosUI
import SwiftData
import SwiftUI
import AXiS

struct CircleDetailBuysSection: View {

    @Environment(\.modelContext) private var modelContext
    @Environment(Events.self) var planner

    let circle: ComiketCircle

    @Query var allBuyEntries: [CirclesBuyEntry]

    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var editingImageItemID: UUID?
    @State private var pendingImage: UIImage?
    @State private var isCropperPresented: Bool = false
    @State private var isPhotoPickerPresented: Bool = false

    var buyEntry: CirclesBuyEntry? {
        allBuyEntries.first {
            $0.circleID == circle.id && $0.eventNumber == planner.activeEventNumber
        }
    }

    var body: some View {
        Section("Buys.Section.Title") {
            if let buyEntry, !buyEntry.items.isEmpty {
                ForEach(Array(buyEntry.items.enumerated()), id: \.element.id) { index, item in
                    buyItemRow(buyEntry: buyEntry, index: index, item: item)
                }
            }
            Button {
                addBlankItem()
            } label: {
                Label("Buys.AddItem", systemImage: "plus.circle.fill")
            }
        }
        .photosPicker(
            isPresented: $isPhotoPickerPresented,
            selection: $selectedPhotoItem,
            matching: .images,
            photoLibrary: .shared()
        )
        .onChange(of: selectedPhotoItem) { _, newPhotoItem in
            Task {
                if let newPhotoItem,
                   let photoData = try? await newPhotoItem.loadTransferable(type: Data.self),
                   let loadedImage = UIImage(data: photoData) {
                    await MainActor.run {
                        pendingImage = loadedImage
                        isCropperPresented = true
                    }
                }
                await MainActor.run {
                    selectedPhotoItem = nil
                }
            }
        }
        .sheet(isPresented: $isCropperPresented) {
            if let pendingImage {
                ImageCropView(
                    image: pendingImage,
                    onCrop: { croppedImage in
                        applyImage(croppedImage)
                        isCropperPresented = false
                    },
                    onCancel: {
                        self.pendingImage = nil
                        editingImageItemID = nil
                        isCropperPresented = false
                    }
                )
            }
        }
    }

    @ViewBuilder
    func buyItemRow(buyEntry: CirclesBuyEntry, index: Int, item: CirclesBuyEntry.BuyItem) -> some View {
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
        .swipeActions(edge: .leading) {
            Button {
                editingImageItemID = item.id
                isPhotoPickerPresented = true
            } label: {
                Label("Buys.SelectImage", systemImage: "photo")
            }
            .tint(.blue)
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                deleteItem(at: index)
            } label: {
                Label("Shared.Delete", systemImage: "trash")
            }
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
            pendingImage = nil
            editingImageItemID = nil
            return
        }
        if let index = buyEntry.items.firstIndex(where: { $0.id == itemID }) {
            buyEntry.items[index].imageData = image.jpegData(compressionQuality: 0.7)
        }
        pendingImage = nil
        editingImageItemID = nil
    }
}
