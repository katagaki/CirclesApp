import AXiS
import ORBiT
import PhotosUI
import SwiftUI
import WebP

/// What the composer opens with: blank for a new item, filled in for a personal one.
struct SharedBuyComposition: Identifiable, Hashable {
    let id = UUID()
    var name: String = ""
    var cost: Int = 0
    var imageData: Data?
    var personalItemID: String?

    var isConversion: Bool { personalItemID != nil }
}

enum SharedBuyImageEncoder {

    static let maxDimension: CGFloat = 1000.0

    /// Scales a photo down to 1000 points on its long edge and encodes it as WebP, lowering
    /// the quality until it fits under the relay's limit.
    static func webp(from data: Data) -> Data? {
        guard let image = UIImage(data: data) else { return nil }
        let scale = min(1.0, maxDimension / max(image.size.width, image.size.height))
        let size = CGSize(width: floor(image.size.width * scale), height: floor(image.size.height * scale))
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1.0
        let resized = UIGraphicsImageRenderer(size: size, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
        for quality: Float in [80.0, 65.0, 50.0, 35.0, 20.0] {
            let encoded = try? WebPEncoder().encode(resized, config: .preset(.photo, quality: quality))
            if let encoded, encoded.count <= SharedBuysSession.maxImageBytes { return encoded }
        }
        return nil
    }
}

/// Pushed inside the panel rather than presented over it: circle detail is already in a
/// sheet, and a second one both hides the map and is dismissed along with its host row.
struct SharedBuyComposerView: View {

    @Environment(SharedBuysSession.self) var sharedBuys
    @Environment(\.dismiss) var dismiss

    let circleID: Int
    var circleName: String?
    var circleSpace: String?
    var attachments: [Data] = []
    let composition: SharedBuyComposition
    var onMoved: (() -> Void)?

    @State private var name: String = ""
    @State private var cost: String = ""
    @State private var imageData: Data?
    @State private var pickedPhoto: PhotosPickerItem?
    @State private var assignToSelf: Bool = true
    @State private var removeFromBuys: Bool = true
    @State private var isPrepared: Bool = false

    var trimmedName: String { name.trimmingCharacters(in: .whitespaces) }

    var body: some View {
        Form {
            Section {
                photoPicker
            }
            Section {
                TextField("Buys.ItemName.Placeholder", text: $name)
                TextField("Buys.ItemCost.Placeholder", text: $cost)
                    .keyboardType(.numberPad)
            }
            Section {
                Toggle("Buys.Shared.Add.AssignToMe", isOn: $assignToSelf)
                if composition.isConversion {
                    Toggle("Buys.Shared.Add.RemoveFromBuys", isOn: $removeFromBuys)
                }
            } footer: {
                if composition.isConversion {
                    Text("Buys.Shared.Add.Visible")
                }
            }
        }
        .navigationTitle(composition.isConversion ? "Buys.Shared.Add.Move" : "Buys.AddItem.Shared")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden()
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(role: .cancel) { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button(role: .confirm) { commit() }
                    .disabled(trimmedName.isEmpty)
            }
        }
        .onAppear {
            // A pushed view appears again when the photo picker closes.
            guard !isPrepared else { return }
            isPrepared = true
            name = composition.name
            cost = composition.cost == 0 ? "" : String(composition.cost)
            imageData = composition.imageData
        }
        .onChange(of: pickedPhoto) { _, photo in
            Task { imageData = try? await photo?.loadTransferable(type: Data.self) }
        }
    }

    @ViewBuilder
    var photoPicker: some View {
        VStack(spacing: 12.0) {
            PhotosPicker(selection: $pickedPhoto, matching: .images) {
                Group {
                    if let imageData, let image = UIImage(data: imageData) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                    } else {
                        VStack(spacing: 6.0) {
                            Image(systemName: "photo.badge.plus")
                                .font(.title2)
                            Text("Buys.Shared.Add.Photo")
                                .font(.footnote)
                        }
                    }
                }
                .frame(width: 120.0, height: 120.0)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 12.0))
            }
            .accessibilityIdentifier("SharedBuyPhoto")
            if !attachments.isEmpty {
                ScrollView(.horizontal) {
                    HStack(spacing: 8.0) {
                        ForEach(Array(attachments.enumerated()), id: \.offset) { index, attachment in
                            Button {
                                imageData = attachment
                            } label: {
                                if let image = UIImage(data: attachment) {
                                    Image(uiImage: image)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 48.0, height: 48.0)
                                        .clipShape(RoundedRectangle(cornerRadius: 6.0))
                                }
                            }
                            .buttonStyle(.plain)
                            .accessibilityIdentifier("SharedBuyAttachment\(index)")
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    func commit() {
        let itemID = sharedBuys.addItem(
            name: trimmedName,
            cost: Int(cost) ?? 0,
            circleID: circleID,
            circleName: circleName,
            circleSpace: circleSpace,
            assignToSelf: assignToSelf
        )
        if let imageData {
            let session = sharedBuys
            let circleID = circleID
            Task {
                let encoded = await Task.detached(priority: .userInitiated) {
                    SharedBuyImageEncoder.webp(from: imageData)
                }.value
                if let encoded { session.attachImage(encoded, to: itemID, circleID: circleID) }
            }
        }
        if composition.isConversion, removeFromBuys { onMoved?() }
        dismiss()
    }
}

/// Pushes the composer inside the panel, raising it to full height for the keyboard and
/// putting it back afterwards. Applied to the detail view, not a row, so that neither
/// presentation is lost when the row scrolls out of the list.
struct SharedBuyComposerPresenter: ViewModifier {

    @Environment(Unifier.self) var unifier
    @Environment(Events.self) var planner

    let circle: ComiketCircle
    let attachments: [Data]
    @Binding var composition: SharedBuyComposition?
    @Binding var assigningItem: SharedBuyItem?

    @State private var detentBeforeComposer: PresentationDetent?

    func body(content: Content) -> some View {
        content
            .sheet(item: $assigningItem) { item in
                SharedBuyAssignSheet(item: item)
            }
            .navigationDestination(item: $composition) { composition in
                SharedBuyComposerView(
                    circleID: circle.id,
                    circleName: circle.circleName,
                    circleSpace: circle.spaceName(),
                    attachments: attachments,
                    composition: composition,
                    onMoved: {
                        guard let itemID = composition.personalItemID else { return }
                        BuysDatabase.shared.deleteItem(id: itemID, eventNumber: planner.activeEventNumber)
                    }
                )
                .opacity(unifier.isMinimized ? 0.0 : 1.0)
                .toolbarVisibility(unifier.isMinimized ? .hidden : .visible, for: .navigationBar, .bottomBar)
            }
            .onChange(of: composition == nil) { _, isClosed in
                guard unifier.displayMode == .sheet else { return }
                if isClosed {
                    if let detentBeforeComposer { unifier.selectedDetent = detentBeforeComposer }
                    detentBeforeComposer = nil
                } else {
                    detentBeforeComposer = unifier.selectedDetent
                    unifier.selectedDetent = .large
                }
            }
    }
}
