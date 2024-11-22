//
//  FavoritesToolbar.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2024/11/16.
//

import Komponents
import SwiftUI

struct FavoritesToolbar: View {

    @Binding var isVisitMode: Bool

    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 12.0) {
                BarAccessoryMenu(
                    "Shared.Sort",
                    icon: "arrow.up.arrow.down"
                ) {
                    // TODO: Do sort
                }
                BarAccessoryButton(
                    "Shared.VisitMode",
                    icon: isVisitMode ? "checkmark.rectangle.stack.fill" : "checkmark.rectangle.stack",
                    isSecondary: !isVisitMode
                ) {
                    withAnimation(.snappy.speed(2.0)) {
                        isVisitMode.toggle()
                    }
                }
                .popoverTip(VisitModeTip())
            }
            .padding(.horizontal, 12.0)
            .padding(.vertical, 12.0)
        }
        .scrollIndicators(.hidden)
    }
}
