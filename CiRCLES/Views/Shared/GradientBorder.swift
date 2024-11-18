//
//  GradientBorder.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2024/11/18.
//

import SwiftUI

// swiftlint:disable identifier_name
struct GradientBorder: View {
    var body: some View {
        GeometryReader { proxy in
            let height: Float = Float(proxy.size.height)
            let width: Float = Float(proxy.size.width)

            let depth: Float = 40.0

            let x1: Float = 0.00
            let x2: Float = depth / width * 0.50
            let x3: Float = depth / width * 0.75
            let x4: Float = depth / width
            let x5: Float = 1.00 - x4
            let x6: Float = 1.00 - x3
            let x7: Float = 1.00 - x2
            let x8: Float = 1.00 - x1

            let y1: Float = 0.00
            let y2: Float = depth / height * 0.50
            let y3: Float = depth / height * 0.75
            let y4: Float = depth / height
            let y5: Float = 1.00 - y4
            let y6: Float = 1.00 - y3
            let y7: Float = 1.00 - y2
            let y8: Float = 1.00 - y1

            let c1: Color = .accent.opacity(0.6)
            let c2: Color = .clear

            let meshMatrix = [
                SIMD2(x1, y1), SIMD2(x2, y1), SIMD2(x3, y1), SIMD2(x4, y1), SIMD2(x5, y1), SIMD2(x6, y1), SIMD2(x7, y1), SIMD2(x8, y1),
                SIMD2(x1, y2), SIMD2(x2, y2), SIMD2(x3, y2), SIMD2(x4, y2), SIMD2(x5, y2), SIMD2(x6, y2), SIMD2(x7, y2), SIMD2(x8, y2),
                SIMD2(x1, y3), SIMD2(x2, y3), SIMD2(x3, y3), SIMD2(x4, y3), SIMD2(x5, y3), SIMD2(x6, y3), SIMD2(x7, y3), SIMD2(x8, y3),
                SIMD2(x1, y4), SIMD2(x2, y4), SIMD2(x3, y4), SIMD2(x4, y4), SIMD2(x5, y4), SIMD2(x6, y4), SIMD2(x7, y4), SIMD2(x8, y4),
                SIMD2(x1, y5), SIMD2(x2, y5), SIMD2(x3, y5), SIMD2(x4, y5), SIMD2(x5, y5), SIMD2(x6, y5), SIMD2(x7, y5), SIMD2(x8, y5),
                SIMD2(x1, y6), SIMD2(x2, y6), SIMD2(x3, y6), SIMD2(x4, y6), SIMD2(x5, y6), SIMD2(x6, y6), SIMD2(x7, y6), SIMD2(x8, y6),
                SIMD2(x1, y7), SIMD2(x2, y7), SIMD2(x3, y7), SIMD2(x4, y7), SIMD2(x5, y7), SIMD2(x6, y7), SIMD2(x7, y7), SIMD2(x8, y7),
                SIMD2(x1, y8), SIMD2(x2, y8), SIMD2(x3, y8), SIMD2(x4, y8), SIMD2(x5, y8), SIMD2(x6, y8), SIMD2(x7, y8), SIMD2(x8, y8)
            ]

            let meshColorMatrix = [
                c1, c1, c1, c1, c1, c1, c1, c1,
                c1, c2, c2, c2, c2, c2, c2, c1,
                c1, c2, c2, c2, c2, c2, c2, c1,
                c1, c2, c2, c2, c2, c2, c2, c1,
                c1, c2, c2, c2, c2, c2, c2, c1,
                c1, c2, c2, c2, c2, c2, c2, c1,
                c1, c2, c2, c2, c2, c2, c2, c1,
                c1, c1, c1, c1, c1, c1, c1, c1
            ]

            Rectangle()
                .fill(
                    MeshGradient(
                        width: 8,
                        height: 8,
                        points: meshMatrix,
                        colors: meshColorMatrix,
                        background: .clear
                    )
                )
        }
        .allowsHitTesting(false)
    }
}
// swiftlint:enable identifier_name
