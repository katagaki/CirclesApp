//
//  FavoritesToolbar.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2024/11/16.
//

import SwiftData
import SwiftUI

struct FavoritesToolbar: ToolbarContent {
    @Environment(Favorites.self) var favorites

    @Binding var displayMode: CircleDisplayMode
    @Binding var listDisplayMode: ListDisplayMode

    var body: some ToolbarContent {

        ToolbarItem(placement: .topBarLeading) {
            HStack {
                DisplayModeSwitcher(mode: $displayMode)
                if displayMode == .list {
                    ListModeSwitcher(mode: $listDisplayMode)
                }
            }
        }

        if #available(iOS 26.0, *) {
            ToolbarSpacer(.fixed, placement: .bottomBar)
        }
        ToolbarItem(placement: .bottomBar) {
            Button {
                withAnimation(.smooth.speed(2.0)) {
                    favorites.isGroupedByColor.toggle()
                }
            } label: {
                ToolbarButtonLabel(
                    "Shared.GroupByColor",
                    image: .system(favorites.isGroupedByColor ?
                    "paintpalette.fill" : "paintpalette"),
                    forceLabelStyle: true
                )
            }
        }
        if #available(iOS 26.0, *) {
            ToolbarSpacer(.flexible, placement: .bottomBar)
        } else {
            ToolbarItem(placement: .bottomBar) {
                Spacer()
            }
        }
        if #available(iOS 26.0, *) {
            ToolbarSpacer(.fixed, placement: .bottomBar)
        }
    }
}
