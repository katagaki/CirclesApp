//
//  InteractiveMapButton.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2024/08/15.
//

import SwiftUI

struct InteractiveMapButton: View {

    @Environment(Database.self) var database
    @Environment(Favorites.self) var favorites

    @Environment(\.colorScheme) var colorScheme
    @Environment(\.modelContext) var modelContext

    var selectedEventDateID: Int
    var layoutBlockID: Int
    var layoutSpaceNumber: Int
    var webCatalogIDs: [Int] = []

    @State var isCircleDetailPopoverPresented: Bool = false

    var body: some View {
        VStack(spacing: 0.0) {
            if webCatalogIDs.count == 0 {
                Rectangle()
                    .foregroundStyle(.clear)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ForEach(webCatalogIDs, id: \.self) { webCatalogID in
                    Group {
                        if let wcIDMappedItems = favorites.wcIDMappedItems,
                           let favoriteCircle = wcIDMappedItems[webCatalogID] {
                            Rectangle()
                                .foregroundStyle(highlightColor(favoriteCircle))
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
            if webCatalogIDs.count > 0 {
                withAnimation(.smooth.speed(2.0)) {
                    isCircleDetailPopoverPresented.toggle()
                }
            }
        }
        .popover(isPresented: $isCircleDetailPopoverPresented.animation(.smooth.speed(2.0))) {
            InteractiveMapDetailPopover(
                isPresented: $isCircleDetailPopoverPresented,
                webCatalogIDs: webCatalogIDs
            )
        }
    }

    func highlightColor(_ favoriteCircle: UserFavorites.Response.FavoriteItem) -> Color {
        switch colorScheme {
        case .light:
            return favoriteCircle.favorite.color.swiftUIColor().opacity(0.5)
        case .dark:
            return favoriteCircle.favorite.color.swiftUIColor().brightness(0.1).opacity(0.5) as? Color ??
            favoriteCircle.favorite.color.swiftUIColor().opacity(0.5)
        @unknown default:
            return favoriteCircle.favorite.color.swiftUIColor().opacity(0.5)
        }
    }
}
