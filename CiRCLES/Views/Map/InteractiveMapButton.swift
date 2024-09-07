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

    var selectedEventDateID: Int
    var layoutSpaceNumber: Int
    var circlesInSpace: [ComiketCircle]?

    @State var isCircleDetailPopoverPresented: Bool = false

    var body: some View {
        VStack(spacing: 0.0) {
            if circlesToDisplay().count == 0 {
                Rectangle()
                    .foregroundStyle(.clear)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ForEach(circlesToDisplay()) { circle in
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
            }
        }
        .contentShape(.rect)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay {
            if isCircleDetailPopoverPresented {
                Color.accent.opacity(0.3)
            }
        }
        .onTapGesture {
            if (circlesInSpace?.count ?? 0) > 0 {
                withAnimation(.smooth.speed(2.0)) {
                    isCircleDetailPopoverPresented.toggle()
                }
            }
        }
        .popover(isPresented: $isCircleDetailPopoverPresented.animation(.smooth.speed(2.0))) {
            InteractiveMapDetailPopover(isPresented: $isCircleDetailPopoverPresented, circles: circlesToDisplay())
        }
    }

    func circlesToDisplay() -> [ComiketCircle] {
        circlesInSpace?
            .filter({$0.day == selectedEventDateID})
            .sorted(by: {$0.spaceNumber < $1.spaceNumber}) ?? []
    }
}
