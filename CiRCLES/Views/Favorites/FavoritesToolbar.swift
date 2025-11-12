//
//  FavoritesToolbar.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2024/11/16.
//

import SwiftData
import SwiftUI

struct FavoritesToolbar: ToolbarContent {
    @Environment(FavoritesCache.self) var favoritesCache

    var body: some ToolbarContent {
        ToolbarItem(placement: .bottomBar) {
            Button {
                withAnimation(.smooth.speed(2.0)) {
                    favoritesCache.isVisitModeOn.toggle()
                    UIApplication.shared.isIdleTimerDisabled = favoritesCache.isVisitModeOn
                }
            } label: {
                ToolbarButtonLabel(
                    "Shared.VisitMode",
                    image: .system(favoritesCache.isVisitModeOn ? "figure.walk.motion" : "figure.walk"),
                    forceLabelStyle: true
                )
            }
            .popoverTip(VisitModeTip())
        }
        if #available(iOS 26.0, *) {
            ToolbarSpacer(.fixed, placement: .bottomBar)
        }
        ToolbarItem(placement: .bottomBar) {
            Button {
                withAnimation(.smooth.speed(2.0)) {
                    favoritesCache.isGroupedByColor.toggle()
                }
            } label: {
                ToolbarButtonLabel(
                    "Shared.GroupByColor",
                    image: .system(favoritesCache.isGroupedByColor ?
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
    }
}
