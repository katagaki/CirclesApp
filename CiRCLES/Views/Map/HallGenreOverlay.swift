//
//  HallGenreOverlay.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2025/06/07.
//

import SwiftUI

struct HallOverlay: View {

    var image: UIImage

    @Binding var width: Int
    @Binding var height: Int
    @Binding var zoomDivisor: Int

    var body: some View {
        Image(uiImage: image)
            .resizable()
            .frame(
                width: CGFloat(width / zoomDivisor),
                height: CGFloat(height / zoomDivisor)
            )
            .animation(.smooth.speed(2.0), value: zoomDivisor)
            .allowsHitTesting(false)
    }
}
