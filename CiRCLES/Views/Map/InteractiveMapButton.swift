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

    @Binding var selectedEventDate: ComiketDate?

    var layout: ComiketLayout

    @State var isCircleDetailPopoverPresented: Bool = false
    @State var circlesInSpace: [ComiketCircle] = []

    var body: some View {
        Button {
            if let selectedEventDate {
                circlesInSpace = database.circles(in: layout, on: selectedEventDate.id)
            } else {
                circlesInSpace = database.circles(in: layout)
            }
            isCircleDetailPopoverPresented.toggle()
        } label: {
            HStack(spacing: 0.0) {
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
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay {
                if isCircleDetailPopoverPresented {
                    Color.accent.opacity(0.3)
                }
            }
        }
//        .onAppear {
//            if circlesInSpace.count == 0 {
//                if let selectedEventDate {
//                    circlesInSpace = database.circles(in: layout, on: selectedEventDate.id)
//                } else {
//                    circlesInSpace = database.circles(in: layout)
//                }
//            }
//        }
        .popover(isPresented: $isCircleDetailPopoverPresented) {
            InteractiveMapDetailPopover(isPresented: $isCircleDetailPopoverPresented, circles: $circlesInSpace)
        }
    }
}
