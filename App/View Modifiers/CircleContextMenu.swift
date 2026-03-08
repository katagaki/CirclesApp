//
//  CircleContextMenu.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2024/11/17.
//

import SwiftData
import SwiftUI

struct CircleContextMenu: ViewModifier {

    @Environment(\.modelContext) var modelContext
    @Environment(Authenticator.self) var authenticator
    @Environment(Favorites.self) var favorites
    @Environment(Database.self) var database
    @Environment(ImageCache.self) var imageCache
    @Environment(Events.self) var planner

    @Query var visits: [CirclesVisitEntry]

    var circle: ComiketCircle
    var open: () -> Void

    init(circle: ComiketCircle, open: @escaping () -> Void) {
        self.circle = circle
        self.open = open
        let circleID = circle.id
        self._visits = Query(
            filter: #Predicate {
                $0.circleID == circleID
            }
        )
    }

    func body(content: Content) -> some View {
        content
            .contextMenu {
                Button("Shared.Open") {
                    open()
                }
                if let visit = visits.first(where: {$0.eventNumber == planner.activeEventNumber}) {
                    Button("Shared.MarkNotVisited", systemImage: "eye.slash") {
                        modelContext.delete(visit)
                    }
                } else {
                    Button("Shared.MarkVisited", systemImage: "eye") {
                        modelContext.insert(
                            CirclesVisitEntry(
                                eventNumber: planner.activeEventNumber,
                                circleID: circle.id
                            )
                        )
                    }
            }
                Divider()
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
                    .modelContainer(sharedModelContainer)
                    .environment(authenticator)
                    .environment(favorites)
                    .environment(database)
                    .environment(imageCache)
                    .environment(planner)
            }
    }
}

extension View {
    func contextMenu(
        circle: ComiketCircle,
        onOpen: @escaping () -> Void
    ) -> some View {
        self.modifier(CircleContextMenu(circle: circle, open: onOpen))
    }
}
