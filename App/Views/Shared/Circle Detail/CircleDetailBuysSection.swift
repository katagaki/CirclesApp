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

    @State private var newItemName: String = ""
    @State private var newItemCost: String = ""
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var pendingImage: UIImage?
    @State private var isCropperPresented: Bool = false

    var buyEntry: CirclesBuyEntry? {
        allBuyEntries.first {
            $0.circleID == circle.id && $0.eventNumber == planner.activeEventNumber
        }
    }

    var body: some View {
        Section("Buys.Section.Title") {
            if let buyEntry, !buyEntry.items.isEmpty {
                ForEach(buyEntry.items) { item in
                    buyItemRow(item)
                }
                .onDelete { indexSet in
                    deleteItems(at: indexSet)
                }
            }
            addItemRow()
        }
    }

    @ViewBuilder
    func buyItemRow(_ item: CirclesBuyEntry.BuyItem) -> some View {
        HStack(spacing: 8.0) {
            if let imageData = item.imageData, let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 36.0, height: 36.0)
                    .clipShape(RoundedRectangle(cornerRadius: 6.0))
            }
            Text(item.name)
            Spacer()
            Text("Buys.CostValue.\(item.cost)")
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    func addItemRow() -> some View {
        VStack(spacing: 8.0) {
            HStack(spacing: 8.0) {
                TextField("Buys.ItemName.Placeholder", text: $newItemName)
                    .textFieldStyle(.roundedBorder)
                TextField("Buys.ItemCost.Placeholder", text: $newItemCost)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.numberPad)
                    .frame(width: 80.0)
            }
            HStack {
                PhotosPicker(
                    selection: $selectedPhotoItem,
                    matching: .images,
                    photoLibrary: .shared()
                ) {
                    Label("Buys.SelectImage", systemImage: "photo")
                        .font(.subheadline)
                }
                .buttonStyle(.bordered)

                if pendingImage != nil {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                }

                Spacer()

                Button {
                    addItem()
                } label: {
                    Label("Buys.AddItem", systemImage: "plus.circle.fill")
                        .font(.subheadline)
                }
                .buttonStyle(.borderedProminent)
                .disabled(newItemName.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding(.vertical, 4.0)
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
                        self.pendingImage = croppedImage
                        isCropperPresented = false
                    },
                    onCancel: {
                        self.pendingImage = nil
                        isCropperPresented = false
                    }
                )
            }
        }
    }

    func addItem() {
        let name = newItemName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        let cost = Int(newItemCost) ?? 0

        var imageData: Data?
        if let pendingImage {
            imageData = pendingImage.jpegData(compressionQuality: 0.7)
        }

        let newItem = CirclesBuyEntry.BuyItem(
            name: name,
            cost: cost,
            imageData: imageData
        )

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

        newItemName = ""
        newItemCost = ""
        self.pendingImage = nil
    }

    func deleteItems(at offsets: IndexSet) {
        guard let buyEntry else { return }
        buyEntry.items.remove(atOffsets: offsets)
        if buyEntry.items.isEmpty {
            modelContext.delete(buyEntry)
        }
    }
}
