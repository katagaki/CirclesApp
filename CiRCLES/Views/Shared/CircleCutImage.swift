//
//  CircleCutImage.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2024/11/09.
//

import SwiftData
import SwiftUI

struct CircleCutImage: View {

    @Environment(Authenticator.self) var authenticator
    @Environment(Favorites.self) var favorites
    @Environment(Database.self) var database
    @Environment(ImageCache.self) var imageCache
    @Environment(Events.self) var planner

    @Binding var showSpaceName: Bool
    @Binding var showDay: Bool

    @Query var visits: [CirclesVisitEntry]

    var circle: ComiketCircle
    var namespace: Namespace.ID
    var cutType: CircleCutType
    var forceReload: Bool
    var showVisitStatus: Bool

    @State var cutImage: UIImage?

    init(
        _ circle: ComiketCircle,
        in namespace: Namespace.ID,
        cutType: CircleCutType = .catalog,
        forceReload: Bool = false,
        showVisitStatus: Bool = true,
        showSpaceName: Binding<Bool>,
        showDay: Binding<Bool>
    ) {
        self.circle = circle
        self.namespace = namespace
        self.cutType = cutType
        self.forceReload = forceReload
        self.showVisitStatus = showVisitStatus
        self._showSpaceName = showSpaceName
        self._showDay = showDay
        let circleID = circle.id
        self._visits = Query(
            filter: #Predicate {
                $0.circleID == circleID
            }
        )
    }

    var body: some View {
        ZStack(alignment: .center) {
            if let cutImage {
                Image(uiImage: cutImage)
                    .resizable()
                    .scaledToFit()
                    .usesPrivacyMode()
            } else {
                noImageAvailableView()
            }
        }
        .aspectRatio(180.0 / 256.0, contentMode: .fit)
        .overlay {
            if database.circleImage(for: circle.id) != nil {
                Canvas { context, size in
                    // Favorite color
                    if let favorites = favorites.wcIDMappedItems,
                       let extendedInformation = circle.extendedInformation,
                       let favorite = favorites[extendedInformation.webCatalogID] {
                        let checkmarkSquareSize = 0.23 * size.width
                        let checkmarkSquareOffset = 0.03 * size.width
                        let checkmarkSquarePath = Path(
                            CGRect(
                                x: checkmarkSquareOffset,
                                y: checkmarkSquareOffset,
                                width: checkmarkSquareSize,
                                height: checkmarkSquareSize
                            )
                        )
                        context.fill(checkmarkSquarePath, with: .color(favorite.favorite.color.backgroundColor()))
                    }

                    // Checkmark for visit status
                    if showVisitStatus,
                        !visits.filter({$0.eventNumber == planner.activeEventNumber}).isEmpty {
                        let checkmarkSize = 0.20 * size.width
                        let checkmarkOffset = 0.045 * size.width
                        if let checkmark = context.resolveSymbol(id: "checkmark") {
                            context.draw(
                                checkmark,
                                in: CGRect(
                                    x: checkmarkOffset,
                                    y: checkmarkOffset,
                                    width: checkmarkSize,
                                    height: checkmarkSize
                                )
                            )
                        }
                    }
                } symbols: {
                    Image(systemName: "checkmark")
                        .fontWeight(.black)
                        .foregroundStyle(checkmarkColor())
                        .tag("checkmark")
                }
                .aspectRatio(180.0 / 256.0, contentMode: .fit)
                .allowsHitTesting(false)
            }
        }
        .overlay {
            if showSpaceName || showDay {
                ZStack(alignment: .bottomTrailing) {
                    VStack(alignment: .trailing, spacing: 2.0) {
                        if showDay {
                            CircleBlockPill("Shared.\(circle.day)th.Day")
                                .matchedGeometryEffect(
                                    id: "\(circle.id).Day", in: namespace
                                )
                        }
                        if showSpaceName, let spaceName = circle.spaceName() {
                            CircleBlockPill(LocalizedStringKey(spaceName))
                                .matchedGeometryEffect(
                                    id: "\(circle.id).Space", in: namespace
                                )
                        }
                    }
                    .padding(2.0)
                    Color.clear
                }
            }
        }
        .onAppear {
            prepareCutImage()
        }
        .onChange(of: circle.id) {
            cutImage = nil
            prepareCutImage()
        }
        .onChange(of: cutType) { _, newValue in
            switch newValue {
            case .catalog:
                cutImage = database.circleImage(for: circle.id)
            case .web:
                prepareCutImage()
            }
        }
    }

    func prepareCutImage() {
        // Set the catalog cut as the default
        if cutImage == nil {
            cutImage = database.circleImage(for: circle.id)
        }
        // Only fetch web cut when cutType is .web and we're online
        if cutType == .web && authenticator.onlineState == .online {
            if let extendedInformation = circle.extendedInformation {
                let circleID = circle.id
                let webCatalogID = extendedInformation.webCatalogID
                Task.detached {
                    try? await webCut(for: circleID, webCatalogID: webCatalogID) { image, data in
                        await MainActor.run {
                            if let image {
                                self.cutImage = image
                            }
                            if let data {
                                imageCache.set(circleID, data: data)
                            }
                        }
                    }
                }
            }
        }
    }

    func webCut(
        for circleID: Int, webCatalogID: Int,
        completion: @escaping ((UIImage?, Data?)) async -> Void
    ) async throws {
        if !forceReload {
            let (isWebCutFetched, image) = imageCache.image(circleID)
            if isWebCutFetched {
                await completion((image, nil))
            }
        }
        if let token = authenticator.token {
            if let circleResponse = await WebCatalog.circle(
                with: webCatalogID, authToken: token
            ),
               let webCatalogInformation = circleResponse.response.circle {
                if webCatalogInformation.cutWebURL != "" {
                    if let webCutURL = URL(string: webCatalogInformation.cutWebURL) {
                        let (image, data) = await ImageCache.download(
                            id: circleID, url: webCutURL
                        )
                        await completion((image, data))
                    }
                } else {
                    ImageCache.saveImage(Data(), named: String(circleID))
                }
            }
        }
        await completion((nil, nil))
    }

    func checkmarkColor() -> Color {
        if let favorites = favorites.wcIDMappedItems,
           let extendedInformation = circle.extendedInformation,
           let favorite = favorites[extendedInformation.webCatalogID] {
            return favorite.favorite.color.foregroundColor()
        } else {
            return .black.opacity(0.9)
        }
    }

    @ViewBuilder
    func noImageAvailableView() -> some View {
        Rectangle()
            .foregroundStyle(Color.primary.opacity(0.05))
            .overlay {
                Text("Circles.NoImage")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
    }
}
