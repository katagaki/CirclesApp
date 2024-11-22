//
//  CircleCutImage.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2024/11/09.
//

import SwiftData
import SwiftUI

struct CircleCutImage: View {

    @Environment(\.modelContext) var modelContext

    @Environment(Authenticator.self) var authenticator
    @Environment(Favorites.self) var favorites
    @Environment(Database.self) var database
    @Environment(ImageCache.self) var imageCache
    @Environment(Planner.self) var planner

    @Binding var showSpaceName: Bool
    @Binding var showDay: Bool

    @Query var visits: [CirclesVisitEntry]

    var circle: ComiketCircle
    var namespace: Namespace.ID
    var shouldFetchWebCut: Bool
    var showCatalogCut: Bool
    var forceWebCutUpdate: Bool
    var showVisitStatus: Bool

    @State var isWebCutURLFetched: Bool = false
    @State var webCutImage: UIImage?

    init(
        _ circle: ComiketCircle,
        in namespace: Namespace.ID,
        shouldFetchWebCut: Bool = false,
        showCatalogCut: Bool = true,
        forceWebCutUpdate: Bool = false,
        showVisitStatus: Bool = true,
        showSpaceName: Binding<Bool>,
        showDay: Binding<Bool>
    ) {
        self.circle = circle
        self.namespace = namespace
        self.shouldFetchWebCut = shouldFetchWebCut
        self.showCatalogCut = showCatalogCut
        self.forceWebCutUpdate = forceWebCutUpdate
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
                if let image = database.circleImage(for: circle.id) {
                    if let webCutImage {
                        Image(uiImage: webCutImage)
                            .resizable()
                            .scaledToFit()
                    } else {
                        if showCatalogCut {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                        } else {
                            if shouldFetchWebCut && !isWebCutURLFetched {
                                ZStack(alignment: .center) {
                                    ProgressView()
                                    Color.clear
                                }
                                .aspectRatio(180.0 / 256.0, contentMode: .fit)
                            } else {
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
                } else {
                    ZStack(alignment: .center) {
                        ProgressView()
                        Color.clear
                    }
                    .aspectRatio(180.0 / 256.0, contentMode: .fit)
                }
            }
            GeometryReader { proxy in
                if showCatalogCut || (shouldFetchWebCut && isWebCutURLFetched && webCutImage != nil) {
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
        .onChange(of: circle.id) { _, _ in
            self.webCutImage = nil
            isWebCutURLFetched = false
            prepareCutImage()
        }
    }

    func prepareCutImage() {
        if shouldFetchWebCut && !isWebCutURLFetched {
            if let extendedInformation = circle.extendedInformation {
                let circleID = circle.id
                let webCatalogID = extendedInformation.webCatalogID
                Task.detached {
                    let webCutImage = try? await webCut(for: circleID, webCatalogID: webCatalogID)
                    await MainActor.run {
                        withAnimation(.smooth.speed(2.0)) {
                            self.webCutImage = webCutImage
                            isWebCutURLFetched = true
                        }
                    }
                }
            }
        }
    }

    func webCut(for circleID: Int, webCatalogID: Int) async throws -> UIImage? {
        if !forceWebCutUpdate {
            let (isWebCutFetched, image) = imageCache.image(circleID)
            if isWebCutFetched {
                return image
            }
        }
        if let token = authenticator.token {
            if let circleResponse = await WebCatalog.circle(
                with: webCatalogID, authToken: token
            ),
               let webCatalogInformation = circleResponse.response.circle {
                if webCatalogInformation.cutWebURL != "" {
                    if let webCutURL = URL(string: webCatalogInformation.cutWebURL) {
                        return await imageCache.download(id: circleID, url: webCutURL)
                    }
                } else {
                    imageCache.saveImage(Data(), named: String(circleID))
                }
            }
        }
        return nil
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
