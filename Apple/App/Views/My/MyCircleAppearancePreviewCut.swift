import SwiftUI

struct MyCircleAppearancePreviewCut: View {

    var palette: [Color]
    var center: SIMD2<Float>
    var spaceName: String
    var day: Int
    var isVisited: Bool
    var showsColor: Bool
    var showsSpaceName: Bool
    var showsDay: Bool

    var body: some View {
        MeshGradient(
            width: 3,
            height: 3,
            points: [
                [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],
                [0.0, 0.5], center, [1.0, 0.5],
                [0.0, 1.0], [0.5, 1.0], [1.0, 1.0]
            ],
            colors: [
                palette[0], palette[1], palette[2],
                palette[3], palette[0], palette[1],
                palette[2], palette[3], palette[0]
            ]
        )
        .grayscale(showsColor ? 0.0 : 1.0)
        .aspectRatio(180.0 / 256.0, contentMode: .fit)
        .overlay {
            GeometryReader { proxy in
                let boxSize = proxy.size.width * 0.22
                Rectangle()
                    .fill(.white)
                    .stroke(.black, lineWidth: 0.75)
                    .overlay {
                        if isVisited {
                            Image(systemName: "checkmark")
                                .resizable()
                                .scaledToFit()
                                .fontWeight(.black)
                                .foregroundStyle(Color.accentColor)
                                .padding(boxSize * 0.15)
                        }
                    }
                    .frame(width: boxSize, height: boxSize)
            }
        }
        .overlay(alignment: .bottomTrailing) {
            if showsSpaceName || showsDay {
                VStack(alignment: .trailing, spacing: 2.0) {
                    if showsDay {
                        CircleBlockPill("Shared.\(day)th.Day", size: .tiny)
                    }
                    if showsSpaceName {
                        CircleBlockPill(LocalizedStringKey(spaceName), size: .tiny)
                    }
                }
                .padding(2.0)
            }
        }
    }
}
