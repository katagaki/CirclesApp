//
//  CircleCutImage.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2024/11/09.
//

import SwiftUI

struct CircleCutImage: View {
    @Environment(Authenticator.self) var authenticator
    @Environment(Favorites.self) var favorites
    @Environment(Database.self) var database
    @Environment(ImageCache.self) var imageCache

    @Binding var showSpaceName: Bool
    @Binding var showDay: Bool

    var circle: ComiketCircle
    var namespace: Namespace.ID
    var shouldFetchWebCut: Bool
    var showCatalogCut: Bool
    var forceWebCutUpdate: Bool

    @State var isWebCutURLFetched: Bool = false
    @State var webCutImage: UIImage?

    init(
        _ circle: ComiketCircle,
        in namespace: Namespace.ID,
        shouldFetchWebCut: Bool = false,
        showCatalogCut: Bool = true,
        forceWebCutUpdate: Bool = false,
        showSpaceName: Binding<Bool>,
        showDay: Binding<Bool>
    ) {
        self.circle = circle
        self.namespace = namespace
        self.shouldFetchWebCut = shouldFetchWebCut
        self.showCatalogCut = showCatalogCut
        self.forceWebCutUpdate = forceWebCutUpdate
        self._showSpaceName = showSpaceName
        self._showDay = showDay
    }

    var body: some View {
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
        .overlay {
            if showCatalogCut || (shouldFetchWebCut && isWebCutURLFetched && webCutImage != nil) {
                GeometryReader { proxy in
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
                        Color.clear
                    }
                }
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
        .task {
            if shouldFetchWebCut && !isWebCutURLFetched {
                let webCutImage = try? await updateWebCut(for: circle)
                isWebCutURLFetched = true
                await MainActor.run {
                    withAnimation(.smooth.speed(2.0)) {
                        self.webCutImage = webCutImage
                    }
                }
            }
        }
    }

    func updateWebCut(for circle: ComiketCircle) async throws -> UIImage? {
        if !forceWebCutUpdate {
            let (isWebCutFetched, image) = imageCache.image(circle.id)
            if isWebCutFetched {
                return image
            }
        }
        return await fetchWebCut(for: circle)
    }

    func fetchWebCut(for circle: ComiketCircle) async -> UIImage? {
        if let token = authenticator.token, let extendedInformation = circle.extendedInformation {
            if let circleResponse = await WebCatalog.circle(
                with: extendedInformation.webCatalogID, authToken: token
            ),
               let webCatalogInformation = circleResponse.response.circle {
                if webCatalogInformation.cutWebURL != "" {
                    if let webCutURL = URL(string: webCatalogInformation.cutWebURL) {
                        return await imageCache.download(id: circle.id, url: webCutURL)
                    }
                } else {
                    imageCache.saveImage(Data(), named: String(circle.id))
                }
            }
        }
        return nil
    }
}
