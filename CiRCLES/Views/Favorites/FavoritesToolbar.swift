//
//  FavoritesToolbar.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2024/11/16.
//

import SwiftData
import SwiftUI

struct FavoritesToolbar: ToolbarContent {

    @Binding var isVisitModeOn: Bool
    @Binding var isGroupedByColor: Bool

    var body: some ToolbarContent {
        ToolbarItem(placement: .bottomBar) {
            Button {
                withAnimation(.smooth.speed(2.0)) {
                    isVisitModeOn.toggle()
                }
            } label: {
                ToolbarButtonLabel(
                    "Shared.VisitMode",
                    imageName: isVisitModeOn ? "figure.walk.motion" : "figure.walk"
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
                    isGroupedByColor.toggle()
                }
            } label: {
                ToolbarButtonLabel(
                    "Shared.GroupByColor",
                    imageName: isGroupedByColor ? "paintpalette.fill" : "paintpalette"
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
