import SwiftUI

struct MyCircleAppearancePreview: View {

    var showsWebCut: Bool
    var showsSpaceName: Bool
    var showsDay: Bool
    var isDoubleTapToVisitEnabled: Bool

    let cuts: [(palette: [Color], center: SIMD2<Float>, spaceName: String, day: Int)] = [
        ([.accentColor, .yellow, .pink, .purple], [0.3, 0.6], "A01a", 1),
        ([.teal, .orange, .indigo, .mint], [0.7, 0.4], "A02b", 1),
        ([.pink, .mint, .accentColor, .orange], [0.4, 0.3], "あ12a", 2),
        ([.orange, .accentColor, .green, .yellow], [0.6, 0.7], "c34b", 2)
    ]

    var cutWidth: CGFloat {
        UIDevice.current.userInterfaceIdiom == .phone ? 76.0 : 68.0
    }

    var body: some View {
        HStack(spacing: 1.0) {
            ForEach(cuts.indices, id: \.self) { index in
                MyCircleAppearancePreviewCut(
                    palette: cuts[index].palette,
                    center: cuts[index].center,
                    spaceName: cuts[index].spaceName,
                    day: cuts[index].day,
                    pillSize: .small,
                    isVisited: isDoubleTapToVisitEnabled && index == 1,
                    showsColor: showsWebCut,
                    showsSpaceName: showsSpaceName,
                    showsDay: showsDay
                )
                .frame(width: cutWidth)
            }
        }
        .frame(maxWidth: .infinity)
        .accessibilityHidden(true)
    }
}
