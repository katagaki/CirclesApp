//
//  CircleList.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2024/09/04.
//

import SwiftUI

struct CircleList: View {

    @Environment(Database.self) var database

    var circles: [ComiketCircle]
    var showsOverlayWhenEmpty: Bool = true
    var displayMode: ListDisplayMode
    var namespace: Namespace.ID
    var onSelect: ((ComiketCircle) -> Void)

    var body: some View {
        List(circles) { circle in
            Button {
                onSelect(circle)
            } label: {
                switch displayMode {
                case .regular:
                    CircleListRegularRow(circle: circle, namespace: namespace)
                case .compact:
                    CircleListCompactRow(circle: circle, namespace: namespace)
                }
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
        }
        .listStyle(.plain)
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
