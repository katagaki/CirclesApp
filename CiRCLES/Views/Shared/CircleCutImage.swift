//
//  CircleCutImage.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2024/11/09.
//

import SwiftUI

struct CircleCutImage: View {
    @Environment(AuthManager.self) var authManager
    @Environment(Favorites.self) var favorites
    @Environment(Database.self) var database

    @Binding var showSpaceName: Bool
    @Binding var showDay: Bool

    var circle: ComiketCircle
    var namespace: Namespace.ID
    var shouldFetchWebCut: Bool

    @State var isWebCutURLFetched: Bool = false
    @State var webCutURL: URL?

    init(
        _ circle: ComiketCircle,
        in namespace: Namespace.ID,
        shouldFetchWebCut: Bool = false,
        showSpaceName: Binding<Bool>,
        showDay: Binding<Bool>
    ) {
        self.circle = circle
        self.namespace = namespace
        self.shouldFetchWebCut = shouldFetchWebCut
        self._showSpaceName = showSpaceName
        self._showDay = showDay
    }

    var body: some View {
        Group {
            if let image = database.circleImage(for: circle.id) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .overlay {
                        if let webCutURL {
                            AsyncImage(url: webCutURL,
                                       transaction: Transaction(animation: .snappy.speed(2.0))
                            ) { result in
                                switch result {
                                case .success(let image):
                                    image
                                        .resizable()
                                        .scaledToFit()
                                default: Color.clear
                                }
                            }
                        }
                    }
            } else {
                ZStack(alignment: .center) {
                    ProgressView()
                    Color.clear
                }
                .aspectRatio(0.7, contentMode: .fit)
            }
        }
        .overlay {
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
                webCutURL = try? await fetchWebCutURL(for: circle)
                isWebCutURLFetched = true
            }
        }
    }

    func fetchWebCutURL(for circle: ComiketCircle) async throws -> URL? {
        if let token = authManager.token, let extendedInformation = circle.extendedInformation {
            if let circleResponse = await WebCatalog.circle(
                with: extendedInformation.webCatalogID, authToken: token
            ),
               let webCatalogInformation = circleResponse.response.circle {
                return URL(string: webCatalogInformation.cutWebURL)
            }
        }
        return nil
    }
}
