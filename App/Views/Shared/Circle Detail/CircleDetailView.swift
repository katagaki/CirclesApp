//
//  CircleDetailView.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2024/07/21.
//

import Komponents
import SwiftData
import SwiftUI
import TipKit
import Translation
import UIKit
import RADiUS
import AXiS

struct CircleDetailView: View {

    @Environment(Authenticator.self) var authenticator
    @Environment(Favorites.self) var favorites
    @Environment(Database.self) var database
    @Environment(Events.self) var planner
    @Environment(Mapper.self) var mapper
    @Environment(Unifier.self) var unifier

    @State var circle: ComiketCircle

    @State var extendedInformation: ComiketCircleExtendedInformation?
    @State var webCatalogInformation: WebCatalogCircle?
    @State var genre: String?
    @State var favoriteMemo: String = ""

    @State var previousCircle: ((ComiketCircle) -> ComiketCircle?)?
    @State var nextCircle: ((ComiketCircle) -> ComiketCircle?)?

    @State var attachments: [CircleAttachment] = []
    @State var selectedAttachment: CircleAttachment?
    @State var isAddingAttachment: Bool = false

    @State var isFirstCircleAlertShowing: Bool = false
    @State var isLastCircleAlertShowing: Bool = false

    // Buys image selection (hoisted to avoid nested sheet dismissal)
    @State var buysAttachmentPickerCircle: ComiketCircle?
    @State var buysCropImage: UIImage?
    @State var buysCropItemID: String?

    @AppStorage(wrappedValue: "", "Circles.Detail.SectionOrder") var sectionOrderStorage: String
    @AppStorage(wrappedValue: "", "Circles.Detail.HiddenSections") var hiddenSectionsStorage: String

    @Namespace var namespace

    var visibleSections: [CircleDetailSection] {
        let order = decodeSectionOrder(sectionOrderStorage)
        let hidden = Set(decodeHiddenSections(hiddenSectionsStorage))
        return order.filter { !hidden.contains($0) }
    }

    var body: some View {
        List {
            Section {
                CircleDetailHero(
                    circle: $circle, extendedInformation: $extendedInformation,
                    favoriteMemo: $favoriteMemo,
                    namespace: namespace
                )
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    .listRowInsets(.init(top: 0.0, leading: 20.0, bottom: 0.0, trailing: 20.0))
            }
            ForEach(visibleSections) { section in
                sectionContent(for: section)
            }
            Section {
                NavigationLink {
                    CircleDetailSectionEditor()
                } label: {
                    Label("Circles.Detail.EditSections", systemImage: "list.bullet.indent")
                }
            } header: {
                Text(verbatim: "")
            }
        }
        .fullScreenCover(item: $selectedAttachment) { attachment in
            AttachmentViewer(attachment: attachment)
        }
        .fullScreenCover(isPresented: $isAddingAttachment) {
            ImagePickerFlowView(
                onComplete: { image in
                    addAttachment(image)
                    isAddingAttachment = false
                },
                onCancel: {
                    isAddingAttachment = false
                }
            )
        }
        .sheet(item: $buysAttachmentPickerCircle) { pickerCircle in
            AttachmentPickerView(
                circle: pickerCircle,
                onSelect: { image in
                    buysAttachmentPickerCircle = nil
                    buysCropImage = image
                },
                onCancel: {
                    buysCropItemID = nil
                    buysAttachmentPickerCircle = nil
                }
            )
        }
        .fullScreenCover(item: Binding(
            get: { buysCropImage.map { BuysCropItem(image: $0) } },
            set: { if $0 == nil { buysCropImage = nil } }
        )) { cropItem in
            ImageCropView(
                image: cropItem.image,
                onCrop: { croppedImage in
                    applyBuysImage(croppedImage)
                    buysCropImage = nil
                },
                onCancel: {
                    buysCropImage = nil
                    buysCropItemID = nil
                }
            )
        }
        .opacity(unifier.isMinimized ? 0.0 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: unifier.selectedDetent)
        .contentMargins(.top, 0.0)
        .listSectionSpacing(.compact)
        .subtitledTitle(circle.circleName, subtitle: circle.penName)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Circles.ShowOnMap", systemImage: "mappin.and.ellipse") {
                    showOnMap()
                }
                .disabled(mapper.highlightTarget != nil)
            }
            if #available(iOS 26.0, *) {
                ToolbarSpacer(.fixed, placement: .topBarTrailing)
            }
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button("Circles.GoPrevious", systemImage: "chevron.left") {
                    goToPreviousCircle()
                }
                Button("Circles.GoNext", systemImage: "chevron.right") {
                    goToNextCircle()
                }
            }
        }
        .toolbar {
            if let extendedInformation {
                CircleDetailToolbar(
                    extendedInformation: extendedInformation,
                    webCatalogInformation: webCatalogInformation,
                    favoriteMemo: $favoriteMemo
                )
            }
        }
        .alert("Alerts.FirstCircle.Title", isPresented: $isFirstCircleAlertShowing) {
            Button("Shared.OK", role: .cancel) {
                // Dismiss the alert; no additional action required.
            }
        }
        .alert("Alerts.LastCircle.Title", isPresented: $isLastCircleAlertShowing) {
            Button("Shared.OK", role: .cancel) {
                // Dismiss the alert; no additional action required.
            }
        }
        .task {
            await prepareCircle()
        }
        .onChange(of: circle.id) {
            Task {
                await prepareCircle()
            }
        }
    }

    @ViewBuilder
    func sectionContent(for section: CircleDetailSection) -> some View {
        switch section {
        case .bookName:
            if circle.bookName.trimmingCharacters(in: .whitespacesAndNewlines) != "" {
                ListSectionWithTranslateButton(title: "Shared.BookName", text: circle.bookName)
            }
        case .genre:
            if let genre {
                ListSectionWithTranslateButton(title: "Shared.Genre", text: genre)
            }
        case .tags:
            if let tags = webCatalogInformation?.tag, tags.trimmingCharacters(in: .whitespaces).count > 0 {
                ListSectionWithTranslateButton(title: "Shared.Tags", text: tags)
            }
        case .memo:
            if circle.memo.trimmingCharacters(in: .whitespacesAndNewlines).count > 0 {
                ListSectionWithTranslateButton(
                    title: "Shared.Memo.Circle", text: circle.memo, showContextMenu: false
                )
            }
        case .attachments:
            Section("Circles.Attachments") {
                if !attachments.isEmpty {
                    ForEach(attachments) { attachment in
                        if let image = UIImage(data: attachment.attachmentBlob) {
                            Button {
                                selectedAttachment = attachment
                                unifier.selectedDetent = .large
                            } label: {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(maxWidth: .infinity)
                            }
                            .listRowInsets(EdgeInsets())
                            .contextMenu {
                                Button(
                                    "Circles.Attachments.Delete", systemImage: "trash",
                                    role: .destructive
                                ) {
                                    deleteAttachment(attachment)
                                }
                            }
                        }
                    }
                }
                Button {
                    isAddingAttachment = true
                } label: {
                    Label("Circles.Attachments.Add", systemImage: "plus.circle.fill")
                }
                .popoverTip(AttachmentAndBuysTip())
            }
        case .buys:
            CircleDetailBuysSection(
                circle: circle,
                buysAttachmentPickerCircle: $buysAttachmentPickerCircle,
                buysCropImage: $buysCropImage,
                buysCropItemID: $buysCropItemID
            )
        }
    }

    func decodeSectionOrder(_ string: String) -> [CircleDetailSection] {
        guard !string.isEmpty, let data = string.data(using: .utf8),
              let rawValues = try? JSONDecoder().decode([Int].self, from: data) else {
            return CircleDetailSection.defaultOrder
        }
        var sections = rawValues.compactMap { CircleDetailSection(rawValue: $0) }
        for section in CircleDetailSection.allCases where !sections.contains(section) {
            sections.append(section)
        }
        return sections
    }

    func decodeHiddenSections(_ string: String) -> [CircleDetailSection] {
        guard !string.isEmpty, let data = string.data(using: .utf8),
              let rawValues = try? JSONDecoder().decode([Int].self, from: data) else {
            return []
        }
        return rawValues.compactMap { CircleDetailSection(rawValue: $0) }
    }

    func prepareCircle() async {
        if let extendedInformation = circle.extendedInformation {
            withAnimation(.smooth.speed(2.0)) {
                self.extendedInformation = extendedInformation
            }
        }
        if let token = authenticator.token, let extendedInformation {
            if let circleResponse = await WebCatalog.circle(
                with: extendedInformation.webCatalogID, authToken: token
            ),
               let webCatalogInformation = circleResponse.response.circle {
                withAnimation(.smooth.speed(2.0)) {
                    self.webCatalogInformation = webCatalogInformation
                }
            }
            favoriteMemo = favorites.wcIDMappedItems?[extendedInformation.webCatalogID]?.favorite.memo ?? ""
        }
        let actor = DataFetcher(database: database.getTextDatabase())
        if let genre = await actor.genre(circle.genreID) {
            self.genre = genre
        }
        loadAttachments()
    }

    func loadAttachments() {
        withAnimation(.smooth.speed(2.0)) {
            attachments = AttachmentsDatabase.shared.attachments(
                eventNumber: circle.eventNumber,
                circleID: circle.id
            )
        }
    }

    func addAttachment(_ image: UIImage) {
        guard let data = image.jpegData(compressionQuality: 0.8) else { return }
        AttachmentsDatabase.shared.insert(
            eventNumber: circle.eventNumber,
            circleID: circle.id,
            attachmentType: "image",
            type: "productList",
            attachmentBlob: data
        )
        loadAttachments()
    }

    func deleteAttachment(_ attachment: CircleAttachment) {
        AttachmentsDatabase.shared.delete(id: attachment.id)
        loadAttachments()
    }

    func goToPreviousCircle() {
        if let previousCircle {
            if let circle = previousCircle(circle) {
                self.circle = circle
                Task {
                    await prepareCircle()
                }
            } else {
                isFirstCircleAlertShowing = true
            }
        } else {
            let circleID = circle.id - 1
            if !goToCircle(with: circleID) {
                isFirstCircleAlertShowing = true
            }
        }
    }

    func goToNextCircle() {
        if let nextCircle {
            if let circle = nextCircle(circle) {
                self.circle = circle
                Task {
                    await prepareCircle()
                }
            } else {
                isLastCircleAlertShowing = true
            }
        } else {
            let circleID = circle.id + 1
            if !goToCircle(with: circleID) {
                isLastCircleAlertShowing = true
            }
        }
    }

    func goToCircle(with id: Int) -> Bool {
        let circles = database.circles([id])
        if circles.count == 1 {
            self.circle = circles.first ?? self.circle
            Task {
                await prepareCircle()
            }
            return true
        } else {
            return false
        }
    }

    func showOnMap() {
        if unifier.selectedDetent == .large {
            unifier.selectedDetent = .height(360)
        }
        mapper.highlightTarget = circle
    }

    func applyBuysImage(_ image: UIImage) {
        guard let itemID = buysCropItemID else { return }
        let eventNumber = planner.activeEventNumber
        if let entry = BuysDatabase.shared.entry(for: circle.id, eventNumber: eventNumber),
           var item = entry.items.first(where: { $0.id == itemID }) {
            item.imageData = image.jpegData(compressionQuality: 0.7)
            BuysDatabase.shared.updateItem(item, eventNumber: eventNumber)
        }
        buysCropItemID = nil
    }
}

struct BuysCropItem: Identifiable {
    let id = UUID()
    let image: UIImage
}
