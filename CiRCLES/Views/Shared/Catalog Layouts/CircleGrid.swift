//
//  CircleGrid.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2024/08/30.
//

import SwiftUI

struct CircleGrid: View {

    @Environment(Authenticator.self) var authenticator
    @Environment(Favorites.self) var favorites
    @Environment(Database.self) var database
    @Environment(ImageCache.self) var imageCache

    let gridSpacing: CGFloat = 1.0

    var circles: [ComiketCircle]
    var showsOverlayWhenEmpty: Bool = true
    var namespace: Namespace.ID
    var onSelect: ((ComiketCircle) -> Void)

    @AppStorage(wrappedValue: false, "Customization.ShowSpaceName") var showSpaceName: Bool
    @AppStorage(wrappedValue: false, "Customization.ShowDay") var showDay: Bool
    @AppStorage(wrappedValue: false, "Customization.ShowWebCut") var showWebCut: Bool

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
                        CircleCutImage(
                            circle, in: namespace, shouldFetchWebCut: showWebCut,
                            showSpaceName: $showSpaceName, showDay: $showDay
                        )
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
                            .environment(authenticator)
                            .environment(favorites)
                            .environment(database)
                            .environment(imageCache)
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
