//
//  MapLayer.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2025/06/07.
//

import SwiftUI

struct MapLayer: View {

    var image: UIImage

    @Binding var width: Int
    @Binding var height: Int

    @AppStorage(wrappedValue: 1, "Map.ZoomDivisor") var zoomDivisor: Int
    @AppStorage(wrappedValue: true, "Customization.UseDarkModeMaps") var useDarkModeMaps: Bool

    var body: some View {
        Image(uiImage: image)
            .resizable()
            .frame(
                width: CGFloat(width / zoomDivisor),
                height: CGFloat(height / zoomDivisor)
            )
            .animation(.smooth.speed(2.0), value: zoomDivisor)
            .colorInvert(adaptive: true, enabled: $useDarkModeMaps)
            .allowsHitTesting(false)
    }
}
