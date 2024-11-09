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
    var layoutType: ComiketLayout.LayoutType
    var webCatalogIDs: [Int] = []

    @State var isCircleDetailPopoverPresented: Bool = false

    var body: some View {
        Group {
            if webCatalogIDs.count == 0 {
                Rectangle()
                    .foregroundStyle(.clear)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                switch layoutType {
                case .aOnLeft, .unknown:
                    HStack(spacing: 0.0) {
                        visibleLayout(webCatalogIDs)
                    }
                case .aOnBottom:
                    VStack(spacing: 0.0) {
                        visibleLayout(webCatalogIDs.reversed())
                    }
                case .aOnRight:
                    HStack(spacing: 0.0) {
                        visibleLayout(webCatalogIDs.reversed())
                    }
                case .aOnTop:
                    VStack(spacing: 0.0) {
                        visibleLayout(webCatalogIDs)
                    }
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

    @ViewBuilder
    func visibleLayout(_ webCatalogIDs: [Int]) -> some View {
        ForEach(webCatalogIDs, id: \.self) { webCatalogID in
            Group {
                #if DEBUG
                Rectangle()
                    .foregroundStyle(Color(red: Double.random(in: 0.0..<1.0),
                                           green: Double.random(in: 0.0..<1.0),
                                           blue: Double.random(in: 0.0..<1.0),
                                           opacity: 0.5))
                    .overlay {
                        if webCatalogID == webCatalogIDs.first {
                            Text(verbatim: "a")
                                .font(.system(size: 12.0, weight: .black))
                        }
                    }
                #else
                if let wcIDMappedItems = favorites.wcIDMappedItems,
                   let favoriteCircle = wcIDMappedItems[webCatalogID] {
                    Rectangle()
                        .foregroundStyle(highlightColor(favoriteCircle))
                } else {
                    Rectangle()
                        .foregroundStyle(.clear)
                }
                #endif
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    func highlightColor(_ favoriteCircle: UserFavorites.Response.FavoriteItem) -> Color {
        switch colorScheme {
        case .light:
            return favoriteCircle.favorite.color.backgroundColor().opacity(0.5)
        case .dark:
            return favoriteCircle.favorite.color.backgroundColor().brightness(0.1).opacity(0.5) as? Color ??
            favoriteCircle.favorite.color.backgroundColor().opacity(0.5)
        @unknown default:
            return favoriteCircle.favorite.color.backgroundColor().opacity(0.5)
        }
    }
}
