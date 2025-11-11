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

    @State var isWebCutURLFetched: Bool = false
    @State var webCutImage: UIImage?

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
        ZStack(alignment: .topLeading) {
            Group {
                switch cutType {
                case .catalog:
                    // Show catalog cut
                    if let catalogImage = database.circleImage(for: circle.id) {
                        Image(uiImage: catalogImage)
                            .resizable()
                            .scaledToFit()
                            .usesPrivacyMode()
                    } else {
                        // No image available
                        Rectangle()
                            .foregroundStyle(Color.primary.opacity(0.05))
                            .overlay {
                                Text("Circles.NoImage")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .aspectRatio(180.0 / 256.0, contentMode: .fit)
                    }

                case .web:
                    // Try to show web cut, fallback to catalog
                    if let webCutImage {
                        // Web cut is available
                        Image(uiImage: webCutImage)
                            .resizable()
                            .scaledToFit()
                            .usesPrivacyMode()
                    } else if authenticator.onlineState == .online && !isWebCutURLFetched {
                        // Still loading web cut, show catalog in background with progress
                        ZStack {
                            if let catalogImage = database.circleImage(for: circle.id) {
                                Image(uiImage: catalogImage)
                                    .resizable()
                                    .scaledToFit()
                                    .usesPrivacyMode()
                            }
                            ProgressView()
                        }
                    } else if let catalogImage = database.circleImage(for: circle.id) {
                        // Fallback to catalog cut
                        Image(uiImage: catalogImage)
                            .resizable()
                            .scaledToFit()
                            .usesPrivacyMode()
                    } else {
                        // No image available
                        Rectangle()
                            .foregroundStyle(Color.primary.opacity(0.05))
                            .overlay {
                                Text("Circles.NoImage")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .aspectRatio(180.0 / 256.0, contentMode: .fit)
                    }
                }
            }
            GeometryReader { proxy in
                if database.circleImage(for: circle.id) != nil {
                    ZStack(alignment: .topLeading) {
                        if let favorites = favorites.wcIDMappedItems,
                           let extendedInformation = circle.extendedInformation,
                           let favorite = favorites[extendedInformation.webCatalogID] {
                            favorite.favorite.color.backgroundColor()
                                .frame(width: 0.23 * proxy.size.width,
                                       height: 0.23 * proxy.size.width)
                                .offset(x: 0.03 * proxy.size.width,
                                        y: 0.03 * proxy.size.width)
                        }
                        if showVisitStatus, !visits.filter({$0.eventNumber == planner.activeEventNumber}).isEmpty {
                            Image(systemName: "checkmark")
                                .resizable()
                                .scaledToFit()
                                .fontWeight(.black)
                                .foregroundStyle(checkmarkColor())
                                .frame(width: 0.20 * proxy.size.width,
                                       height: 0.20 * proxy.size.width)
                                .offset(x: 0.045 * proxy.size.width,
                                        y: 0.045 * proxy.size.width)
                        }
                        Color.clear
                    }
                }
            }
            .aspectRatio(180.0 / 256.0, contentMode: .fit)
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
            self.webCutImage = nil
            isWebCutURLFetched = false
            prepareCutImage()
        }
        .onChange(of: cutType) {
            prepareCutImage()
        }
    }

    func prepareCutImage() {
        // Only fetch web cut when cutType is .web and we're online
        if cutType == .web && authenticator.onlineState == .online && !isWebCutURLFetched {
            if let extendedInformation = circle.extendedInformation {
                let circleID = circle.id
                let webCatalogID = extendedInformation.webCatalogID
                Task.detached {
                    try? await webCut(for: circleID, webCatalogID: webCatalogID) { image, data in
                        await MainActor.run {
                            withAnimation(.smooth.speed(2.0)) {
                                if let image {
                                    self.webCutImage = image
                                }
                                if let data {
                                    imageCache.set(circleID, data: data)
                                }
                                isWebCutURLFetched = true
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
}
