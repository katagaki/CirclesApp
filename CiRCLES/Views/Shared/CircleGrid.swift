//
//  CircleGrid.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2024/08/30.
//

import SwiftUI

struct CircleGrid: View {

    @Environment(Database.self) var database
    @Environment(Favorites.self) var favorites

    let gridSpacing: CGFloat = 1.0

    var circles: [ComiketCircle]
    var showsOverlayWhenEmpty: Bool = true
    var namespace: Namespace.ID
    var onSelect: ((ComiketCircle) -> Void)

    @AppStorage(wrappedValue: false, "Customization.ShowSpaceName") var showSpaceName: Bool
    @AppStorage(wrappedValue: false, "Customization.ShowDay") var showDay: Bool

    var body: some View {
        let phoneColumnConfiguration = [GridItem(.adaptive(minimum: 70.0), spacing: gridSpacing)]
        #if targetEnvironment(macCatalyst)
        let padOrMacColumnConfiguration = [GridItem(.adaptive(minimum: 80.0), spacing: gridSpacing)]
        #else
        let padOrMacColumnConfiguration = [GridItem(.adaptive(minimum: 100.0), spacing: gridSpacing)]
        #endif

        ScrollView {
            LazyVGrid(columns: UIDevice.current.userInterfaceIdiom == .phone ?
                      phoneColumnConfiguration : padOrMacColumnConfiguration,
                      spacing: gridSpacing) {
                ForEach(circles) { circle in
                    Button {
                        onSelect(circle)
                    } label: {
                        Group {
                            if let image = database.circleImage(for: circle.id) {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFit()
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
                                        favorite.favorite.color.swiftUIColor()
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
                                                .matchedGeometryEffect(id: "\(circle.id).Day", in: namespace)
                                        }
                                        if showSpaceName, let spaceName = circle.spaceName() {
                                            CircleBlockPill(LocalizedStringKey(spaceName))
                                                .matchedGeometryEffect(id: "\(circle.id).Space", in: namespace)
                                        }
                                    }
                                    .padding(2.0)
                                    Color.clear
                                }
                            }
                        }
                        .matchedGeometryEffect(id: "\(circle.id).Cut", in: namespace)
                    }
                    .contextMenu {
                        if let twitterURL = circle.extendedInformation?.twitterURL {
                            SNSButton(twitterURL, type: .twitter)
                        }
                        if let pixivURL = circle.extendedInformation?.pixivURL {
                            SNSButton(pixivURL, type: .pixiv)
                        }
                        if let circleMsPortalURL = circle.extendedInformation?.circleMsPortalURL {
                            SNSButton(circleMsPortalURL, type: .circleMs)
                        }
                    } preview: {
                        CirclePreview(database: database, circle: circle)
                    }
                    .automaticMatchedTransitionSource(id: circle.id, in: namespace)
                }
            }
        }
        .overlay {
            if circles.isEmpty && showsOverlayWhenEmpty {
                ContentUnavailableView(
                    "Circles.NoCircles",
                    systemImage: "questionmark.square.dashed",
                    description: Text("Circles.NoCircles.Description")
                )
            }
        }
    }
}
