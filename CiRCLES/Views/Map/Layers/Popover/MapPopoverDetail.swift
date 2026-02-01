//
//  MapPopoverDetail.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2024/08/15.
//

import SwiftUI
import TipKit

struct MapPopoverDetail: View {

    @Environment(Database.self) var database
    @Environment(Unifier.self) var unifier
    @Environment(Favorites.self) var favorites
    @Environment(Events.self) var planner

    @Environment(\.modelContext) var modelContext

    @State var selection: PopoverData?

    @State var circles: [ComiketCircle]?

    @AppStorage(wrappedValue: false, "Customization.ShowWebCut") var showWebCut: Bool

    @Namespace var popoverNamespace

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8.0) {
                if let circles {
                    ForEach(Array(circles.enumerated()), id: \.element.id) { index, circle in
                        HStack {
                            CircleCutImage(
                                circle, in: popoverNamespace, cutType: .web,
                                showSpaceName: .constant(false), showDay: .constant(false)
                            )
                            .frame(width: 49.0, height: 70.0, alignment: .center)
                            VStack(alignment: .leading, spacing: 2.0) {
                                Text(circle.circleName)
                                    .lineLimit(2)
                                if let extendedInfo = circle.extendedInformation,
                                   let memo = favorites.wcIDMappedItems?[extendedInfo.webCatalogID]?.favorite.memo,
                                   !memo.isEmpty {
                                    Text(memo)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(2)
                                }
                            }
                            Spacer(minLength: 0.0)
                        }
                        .contentShape(.rect)
                        .onTapGesture(count: 2) {
                            let circleID = circle.id
                            let eventNumber = planner.activeEventNumber
                            Task.detached {
                                let actor = VisitActor(modelContainer: sharedModelContainer)
                                await actor.toggleVisit(circleID: circleID, eventNumber: eventNumber)
                            }
                        }
                        .onTapGesture {
                            if unifier.isMinimized {
                                unifier.selectedDetent = .height(360)
                            }
                            unifier.append(.circleDetail(circle: circle))
                        }
                        .popoverTip(index == 0 ? DoubleTapVisitTip() : nil)
                    }
                } else {
                    ProgressView()
                        .padding()
                }
            }
            .presentationCompactAdaptation(.popover)
            .onAppear {
                fetchCircles()
            }
        }
    }

    func fetchCircles() {
        if let selection {
            Task.detached {
                let actor = DataFetcher(modelContainer: sharedModelContainer)
                let circleIdentifiers = await actor.circles(withWebCatalogIDs: selection.ids)
                await MainActor.run {
                    let circles = database.circles(circleIdentifiers, reversed: selection.reversed)
                    self.circles = circles
                }
            }
        }
    }
}
