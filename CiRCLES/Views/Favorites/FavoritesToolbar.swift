//
//  FavoritesToolbar.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2024/11/16.
//

import Komponents
import SwiftData
import SwiftUI

struct FavoritesToolbar: View {

    @Binding var isVisitModeOn: Bool
    @Binding var isGroupedByColor: Bool

    @State var isInitialLoadCompleted: Bool = false

    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 12.0) {
                BarAccessoryButton(
                    "Shared.VisitMode",
                    icon: isVisitModeOn ? "checkmark.rectangle.stack.fill" : "checkmark.rectangle.stack",
                    isSecondary: !isVisitModeOn
                ) {
                    withAnimation(.smooth.speed(2.0)) {
                        isVisitModeOn.toggle()
                    }
                }
                .popoverTip(VisitModeTip())
                BarAccessoryButton(
                    "Shared.GroupByColor",
                    icon: isGroupedByColor ? "paintpalette.fill" : "paintpalette",
                    isSecondary: !isGroupedByColor
                ) {
                    withAnimation(.smooth.speed(2.0)) {
                        isGroupedByColor.toggle()
                    }
                }
//                BarAccessoryMenu(
//                    "Shared.Sort",
//                    icon: "arrow.up.arrow.down"
//                ) {
//                    
//                }
            }
            .padding(.horizontal, 12.0)
            .padding(.vertical, 12.0)
        }
        .scrollIndicators(.hidden)
    }
}
