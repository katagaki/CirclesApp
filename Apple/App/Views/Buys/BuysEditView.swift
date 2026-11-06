import AXiS
import ORBiT
import PhotosUI
import SwiftUI
import WebP

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

/// The row being edited. New rows exist only here until they have a name, so an abandoned
/// one is never written to the database or sent to the room.
enum BuysEditTarget: Hashable {
    case personal(String)
    case shared(String)
    case newPersonal
    case newShared

    var isNew: Bool { self == .newPersonal || self == .newShared }
}

enum BuysEditField: Hashable {
    case name
    case cost
}

/// Every item for a circle in one view, edited in place.
///
/// Pushed inside the panel rather than presented over it, because circle detail is already
/// in a sheet. Shared edits go out when a row is finished, not per keystroke: the relay
/// allows 20 messages per 10 seconds, and a half-typed name should not reach other members.
struct BuysEditView: View {

    static let quickCosts: [Int] = [500, 1000, 1500, 2000, 3000]

    @Environment(SharedBuysSession.self) var sharedBuys

    var circle: ComiketCircle?
    let circleID: Int
    var circleName: String?
    var circleSpace: String?
    let eventNumber: Int

    @State private var personal: [BuyItem] = []
    @State private var editing: BuysEditTarget?
    @State private var draftName: String = ""
    @State private var draftCost: String = ""
    @State private var moving: BuyItem?
    @State private var attachmentTarget: BuysEditTarget?
    @State private var pickerCircle: ComiketCircle?
    @State private var cropImage: UIImage?
    @FocusState private var focus: BuysEditField?

    var shared: [SharedBuyItem] { sharedBuys.items.filter { $0.circleID == circleID } }

    var body: some View {
        ScrollViewReader { proxy in
            List {
                personalSection
                if sharedBuys.isActive { sharedSection }
            }
            .scrollDismissesKeyboard(.interactively)
            // The keyboard drops for a moment between fields. Without room to spare the
            // list clamps its offset and the row ends up behind the keyboard.
            .contentMargins(.bottom, editing == nil ? 0.0 : 360.0, for: .scrollContent)
            .onChange(of: editing) { reveal(proxy) }
            .onChange(of: focus) { _, field in
                if field == nil {
                    finishEditing()
                } else {
                    reveal(proxy)
                }
            }
            .onReceive(
                NotificationCenter.default.publisher(for: UIResponder.keyboardDidChangeFrameNotification)
            ) { _ in
                reveal(proxy)
            }
        }
        .navigationTitle("Buys.Edit.Title")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                trailingButton
            }
            ToolbarItemGroup(placement: .keyboard) {
                if focus == .cost { quickCostButtons }
            }
        }
        .confirmationDialog(
            "Buys.Shared.Move.Confirm",
            isPresented: Binding(get: { moving != nil }, set: { if !$0 { moving = nil } }),
            titleVisibility: .visible,
            presenting: moving
        ) { item in
            Button("Buys.Shared.Add.Move") { moveToShared(item) }
        } message: { _ in
            Text("Buys.Shared.Add.Visible")
        }
        .sheet(item: $pickerCircle) { pickerCircle in
            AttachmentPickerView(
                circle: pickerCircle,
                onSelect: { image in
                    self.pickerCircle = nil
                    cropImage = image
                },
                onCancel: {
                    attachmentTarget = nil
                    self.pickerCircle = nil
                }
            )
        }
        .fullScreenCover(item: Binding(
            get: { cropImage.map { BuysCropItem(image: $0) } },
            set: { if $0 == nil { cropImage = nil } }
        )) { cropItem in
            ImageCropView(
                image: cropItem.image,
                onCrop: { cropped in
                    if let attachmentTarget, let data = cropped.jpegData(compressionQuality: 0.7) {
                        applyPhoto(data, to: attachmentTarget)
                    }
                    cropImage = nil
                    attachmentTarget = nil
                },
                onCancel: {
                    cropImage = nil
                    attachmentTarget = nil
                }
            )
        }
        .onAppear(perform: reload)
        .onDisappear(perform: finishEditing)
    }

    @ViewBuilder
    var trailingButton: some View {
        if editing != nil {
            Button(role: .confirm) { focus = nil }
        } else if sharedBuys.isActive {
            Menu {
                Button("Buys.Edit.AddToMine", systemImage: "person") { begin(.newPersonal) }
                Button("Buys.AddItem.Shared", systemImage: "person.2") { begin(.newShared) }
            } label: {
                Label("Buys.AddItem", systemImage: "plus")
            }
        } else {
            Button("Buys.AddItem", systemImage: "plus") { begin(.newPersonal) }
        }
    }

    var quickCostButtons: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 20.0) {
                ForEach(Self.quickCosts, id: \.self) { cost in
                    Button {
                        draftCost = String(cost)
                    } label: {
                        Text(verbatim: "¥\(cost.formatted(.number))")
                            .monospacedDigit()
                    }
                }
            }
        }
        .scrollIndicators(.hidden)
    }

    @ViewBuilder
    var personalSection: some View {
        Section {
            ForEach(personal) { item in
                row(.personal(item.id), name: item.name, cost: item.cost, photo: item.imageData)
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            BuysDatabase.shared.deleteItem(id: item.id, eventNumber: eventNumber)
                            reload()
                        } label: {
                            Label("Shared.Delete", systemImage: "trash")
                        }
                    }
                    .swipeActions(edge: .leading) { moveButton(item).tint(.accentColor) }
                    .contextMenu { moveButton(item) }
            }
            .onMove { from, destination in
                BuysDatabase.shared.moveItems(
                    circleID: circleID,
                    eventNumber: eventNumber,
                    fromOffsets: from,
                    toOffset: destination
                )
                reload()
            }
            if editing == .newPersonal {
                row(.newPersonal, name: "", cost: 0, photo: nil)
            }
        } header: {
            Text("Buys.Section.Title")
        }
    }

    @ViewBuilder
    var sharedSection: some View {
        Section {
            ForEach(shared) { item in
                row(.shared(item.id), name: item.name, cost: item.cost, photo: sharedBuys.image(for: item))
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            sharedBuys.remove(itemID: item.id, circleID: item.circleID)
                        } label: {
                            Label("Shared.Delete", systemImage: "trash")
                        }
                    }
                    .swipeActions(edge: .leading) { copyButton(item).tint(.accentColor) }
                    .contextMenu { copyButton(item) }
            }
            if editing == .newShared {
                row(.newShared, name: "", cost: 0, photo: nil)
            }
        } header: {
            Text("Buys.Shared.Title")
        }
    }

    @ViewBuilder
    func moveButton(_ item: BuyItem) -> some View {
        if sharedBuys.isActive {
            Button {
                moving = item
            } label: {
                Label("Buys.Shared.Add.Move", systemImage: "person.2.fill")
            }
        }
    }

    func copyButton(_ item: SharedBuyItem) -> some View {
        Button {
            copyToPersonal(item)
        } label: {
            Label("Buys.Shared.Copy", systemImage: "doc.on.doc")
        }
    }

    func row(_ target: BuysEditTarget, name: String, cost: Int, photo: Data?) -> some View {
        HStack(spacing: 10.0) {
            if !target.isNew {
                BuysEditThumbnail(
                    photo: photo,
                    hasAttachments: !attachments.isEmpty,
                    onPhoto: { applyPhoto($0, to: target) },
                    onChooseAttachment: { chooseAttachment(for: target) }
                )
            }
            if editing == target {
                TextField("Buys.ItemName.Placeholder", text: $draftName)
                    .focused($focus, equals: .name)
                    .submitLabel(.next)
                    .onSubmit { focus = .cost }
                TextField("Buys.ItemCost.Placeholder", text: $draftCost)
                    .focused($focus, equals: .cost)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 80.0)
            } else {
                Text(name)
                Spacer()
                Text("Buys.CostValue.\(cost)")
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if editing != target { begin(target, name: name, cost: cost) }
        }
        .id(target)
    }

    var attachments: [Data] {
        guard let circle else { return [] }
        return AttachmentsDatabase.shared
            .attachments(eventNumber: circle.eventNumber, circleID: circle.id)
            .map(\.attachmentBlob)
    }

    func reload() {
        personal = BuysDatabase.shared.entry(for: circleID, eventNumber: eventNumber)?.items ?? []
    }

    func begin(_ target: BuysEditTarget, name: String = "", cost: Int = 0) {
        finishEditing()
        draftName = name
        draftCost = cost == 0 ? "" : String(cost)
        editing = target
        focus = .name
    }

    /// Runs twice because the list's insets are still moving when the keyboard reports in.
    func reveal(_ proxy: ScrollViewProxy) {
        guard let editing else { return }
        Task {
            for delay in [100, 350] {
                try? await Task.sleep(for: .milliseconds(delay))
                withAnimation { proxy.scrollTo(editing, anchor: .center) }
            }
        }
    }

    func finishEditing() {
        guard let target = editing else { return }
        editing = nil
        let name = draftName.trimmingCharacters(in: .whitespaces)
        let cost = Int(draftCost) ?? 0
        switch target {
        case .newPersonal:
            guard !name.isEmpty else { return }
            BuysDatabase.shared.addItem(BuyItem(name: name, cost: cost), circleID: circleID, eventNumber: eventNumber)
            reload()
        case .newShared:
            guard !name.isEmpty else { return }
            addShared(name: name, cost: cost)
        case .personal(let id):
            guard !name.isEmpty, var item = personal.first(where: { $0.id == id }) else { return }
            item.name = name
            item.cost = cost
            BuysDatabase.shared.updateItem(item, eventNumber: eventNumber)
            reload()
        case .shared(let id):
            guard !name.isEmpty, let item = shared.first(where: { $0.id == id }) else { return }
            if name != item.name { sharedBuys.rename(itemID: id, circleID: circleID, to: name) }
            if cost != item.cost { sharedBuys.setCost(itemID: id, circleID: circleID, to: cost) }
        }
    }

    @discardableResult
    func addShared(name: String, cost: Int) -> String {
        sharedBuys.addItem(
            name: name,
            cost: cost,
            circleID: circleID,
            circleName: circleName,
            circleSpace: circleSpace
        )
    }

    func moveToShared(_ item: BuyItem) {
        let itemID = addShared(name: item.name, cost: item.cost)
        if item.status != .pending {
            sharedBuys.setStatus(itemID: itemID, circleID: circleID, to: item.status.rawValue)
        }
        if let data = item.imageData { applyPhoto(data, to: .shared(itemID)) }
        BuysDatabase.shared.deleteItem(id: item.id, eventNumber: eventNumber)
        reload()
    }

    /// A copy, not a move: removing something from a group list is what Delete is for.
    func copyToPersonal(_ item: SharedBuyItem) {
        let copy = BuyItem(
            name: item.name,
            cost: item.cost,
            imageData: sharedBuys.image(for: item),
            status: BuyItemStatus(rawValue: item.rawStatus) ?? .pending
        )
        BuysDatabase.shared.addItem(copy, circleID: circleID, eventNumber: eventNumber)
        reload()
    }

    func chooseAttachment(for target: BuysEditTarget) {
        attachmentTarget = target
        if attachments.count == 1, let image = UIImage(data: attachments[0]) {
            cropImage = image
        } else {
            pickerCircle = circle
        }
    }

    func applyPhoto(_ data: Data, to target: BuysEditTarget) {
        switch target {
        case .personal(let id):
            guard var item = personal.first(where: { $0.id == id }) else { return }
            item.imageData = data
            BuysDatabase.shared.updateItem(item, eventNumber: eventNumber)
            reload()
        case .shared(let id):
            let session = sharedBuys
            let circleID = circleID
            Task {
                let encoded = await Task.detached(priority: .userInitiated) {
                    SharedBuyImageEncoder.webp(from: data)
                }.value
                if let encoded { session.attachImage(encoded, to: id, circleID: circleID) }
            }
        case .newPersonal, .newShared:
            break
        }
    }
}

struct BuysEditThumbnail: View {

    let photo: Data?
    let hasAttachments: Bool
    let onPhoto: (Data) -> Void
    let onChooseAttachment: () -> Void

    @State private var picked: PhotosPickerItem?
    @State private var isPicking: Bool = false

    var body: some View {
        Menu {
            Button("Buys.Shared.Add.Photo") { isPicking = true }
            if hasAttachments {
                Button("Buys.SelectFromAttachments", action: onChooseAttachment)
            }
        } label: {
            Group {
                if let photo, let image = UIImage(data: photo) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                } else {
                    Image(systemName: "photo")
                        .font(.system(size: 22.0))
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 64.0, height: 64.0)
            .background(Color(.systemGray5))
            .clipShape(RoundedRectangle(cornerRadius: 8.0))
        }
        // Not a PhotosPicker in the menu: closing the menu takes its presentation with it.
        .photosPicker(isPresented: $isPicking, selection: $picked, matching: .images)
        .onChange(of: picked) { _, item in
            Task {
                if let data = try? await item?.loadTransferable(type: Data.self) { onPhoto(data) }
            }
        }
    }
}

/// Pushes the edit view inside the panel, raising it to full height for the keyboard and
/// putting it back afterwards. Applied to the detail view, not a row, so that neither
/// presentation is lost when the row scrolls out of the list.
struct BuysEditPresenter: ViewModifier {

    @Environment(Unifier.self) var unifier
    @Environment(Events.self) var planner

    let circle: ComiketCircle
    @Binding var isEditing: Bool
    @Binding var assigningItem: SharedBuyItem?

    @State private var detentBeforeEditing: PresentationDetent?

    func body(content: Content) -> some View {
        content
            .sheet(item: $assigningItem) { item in
                SharedBuyAssignSheet(item: item)
            }
            .navigationDestination(isPresented: $isEditing) {
                BuysEditView(
                    circle: circle,
                    circleID: circle.id,
                    circleName: circle.circleName,
                    circleSpace: circle.spaceName(),
                    eventNumber: planner.activeEventNumber
                )
                .opacity(unifier.isMinimized ? 0.0 : 1.0)
                .toolbarVisibility(unifier.isMinimized ? .hidden : .visible, for: .navigationBar, .bottomBar)
            }
            .onChange(of: isEditing) { _, isOpen in
                guard unifier.displayMode == .sheet else { return }
                if isOpen {
                    detentBeforeEditing = unifier.selectedDetent
                    unifier.selectedDetent = .large
                } else {
                    if let detentBeforeEditing { unifier.selectedDetent = detentBeforeEditing }
                    detentBeforeEditing = nil
                }
            }
    }
}
