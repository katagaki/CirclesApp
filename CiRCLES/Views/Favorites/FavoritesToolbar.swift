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
                    icon: "checkmark.rectangle.stack",
                    isSecondary: !isVisitMode
                ) {
                    withAnimation(.snappy.speed(2.0)) {
                        isVisitMode.toggle()
                    }
                }
                .popoverTip(VisitModeTip())
            }
            .padding([.leading, .trailing], 12.0)
            .padding([.top, .bottom], 12.0)
        }
        .scrollIndicators(.hidden)
    }
}
