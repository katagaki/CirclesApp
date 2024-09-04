//
//  InteractiveMapButton.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2024/08/15.
//

import SwiftUI

struct InteractiveMapButton: View {

    @Environment(DatabaseManager.self) var database
    @Environment(FavoritesManager.self) var favorites

    @Environment(\.modelContext) var modelContext

    @Binding var selectedEventDate: ComiketDate?

    var layout: ComiketLayout

    @State var isCircleDetailPopoverPresented: Bool = false
    @State var circlesInSpace: [ComiketCircle]?

    var body: some View {
        Button {
            if (circlesInSpace?.count ?? 0) > 0 {
                isCircleDetailPopoverPresented.toggle()
            }
        } label: {
            VStack(spacing: 0.0) {
                if let circlesInSpace {
                    ForEach(circlesInSpace) { circle in
                        Group {
                            if let extendedInformation = circle.extendedInformation,
                               let wcIDMappedItems = favorites.wcIDMappedItems,
                               let favoriteCircle = wcIDMappedItems[extendedInformation.webCatalogID] {
                                Rectangle()
                                    .foregroundStyle(favoriteCircle.favorite.color.swiftUIColor().opacity(0.5))
                            } else {
                                Rectangle()
                                    .foregroundStyle(.clear)
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                } else {
                    Rectangle()
                        .foregroundStyle(.clear)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay {
                if isCircleDetailPopoverPresented {
                    Color.accent.opacity(0.3)
                }
            }
        }
        .onAppear {
            if circlesInSpace == nil {
                Task.detached {
                    await reloadCirclesInSpace()
                }
            }
        }
        .popover(isPresented: $isCircleDetailPopoverPresented) {
            InteractiveMapDetailPopover(isPresented: $isCircleDetailPopoverPresented, circles: $circlesInSpace)
        }
    }

    func reloadCirclesInSpace() async {
        let actor = DataFetcher(modelContainer: sharedModelContainer)
        let blockID = layout.blockID
        let spaceNumber = layout.spaceNumber
        let circleIdentifiersInSpace = await actor.circles(inBlock: blockID, inSpace: spaceNumber)
        await MainActor.run {
            var circlesInSpace = database.circles(circleIdentifiersInSpace, in: modelContext)
            if let selectedEventDate {
                circlesInSpace.removeAll(where: {$0.day != selectedEventDate.id})
            }
            self.circlesInSpace = circlesInSpace
        }
    }
}
