//
//  MapLayer.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2025/06/07.
//

import SwiftUI

struct MapLayer: View {

    @Binding var canvasSize: CGSize
    var image: UIImage

    @AppStorage(wrappedValue: true, "Customization.UseDarkModeMaps") var useDarkModeMaps: Bool

    var body: some View {
        Image(uiImage: image)
            .resizable()
            .colorInvert(adaptive: true, enabled: $useDarkModeMaps)
            .frame(width: canvasSize.width, height: canvasSize.height)
            .allowsHitTesting(false)
    }
}
