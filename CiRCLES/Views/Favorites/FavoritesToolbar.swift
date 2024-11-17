//
//  FavoritesToolbar.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2024/11/16.
//

import Komponents
import SwiftUI

struct FavoritesToolbar: View {
    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 12.0) {
                BarAccessoryMenu("Shared.Sort") {
                    // TODO: Do sort
                }
            }
            .padding([.leading, .trailing], 12.0)
            .padding([.top, .bottom], 12.0)
        }
        .scrollIndicators(.hidden)
    }
}
