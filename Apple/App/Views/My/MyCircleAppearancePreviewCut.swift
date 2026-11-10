import SwiftUI

struct MyCircleAppearancePreviewCut: View {

    var palette: [Color]
    var center: SIMD2<Float>
    var spaceName: String
    var day: Int
    var pillSize: CircleBlockPillSize
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
                let width = proxy.size.width
                ZStack(alignment: .topLeading) {
                    Rectangle()
                        .fill(.white)
                        .strokeBorder(.black, lineWidth: width * 0.03)
                        .overlay {
                            if isVisited {
                                Image(systemName: "checkmark")
                                    .resizable()
                                    .scaledToFit()
                                    .fontWeight(.black)
                                    .foregroundStyle(.black)
                                    .padding(width * 0.075)
                            }
                        }
                        .frame(width: width * 0.275, height: width * 0.275)
                    Rectangle()
                        .fill(.black)
                        .frame(width: width, height: width * 0.03)
                        .offset(y: width * 0.245)
                    Rectangle()
                        .strokeBorder(.black, lineWidth: width * 0.03)
                }
            }
        }
        .overlay(alignment: .bottomTrailing) {
            if showsSpaceName || showsDay {
                VStack(alignment: .trailing, spacing: 2.0) {
                    if showsDay {
                        CircleBlockPill("Shared.\(day)th.Day", size: pillSize)
                    }
                    if showsSpaceName {
                        CircleBlockPill(LocalizedStringKey(spaceName), size: pillSize)
                    }
                }
                .padding(2.0)
            }
        }
    }
}
