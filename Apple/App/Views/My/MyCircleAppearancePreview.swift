import SwiftUI

struct MyCircleAppearancePreview: View {

    var showsWebCut: Bool
    var showsSpaceName: Bool
    var showsDay: Bool
    var isDoubleTapToVisitEnabled: Bool

    let cuts: [(palette: [Color], center: SIMD2<Float>, spaceName: String, day: Int)] = [
        ([.accentColor, .yellow, .pink, .purple], [0.3, 0.6], "東A01a", 1),
        ([.teal, .orange, .indigo, .mint], [0.7, 0.4], "東A02b", 1),
        ([.pink, .mint, .accentColor, .orange], [0.4, 0.3], "西あ12a", 2),
        ([.orange, .accentColor, .green, .yellow], [0.6, 0.7], "南c34b", 2)
    ]

    var body: some View {
        HStack(spacing: 1.0) {
            ForEach(cuts.indices, id: \.self) { index in
                MyCircleAppearancePreviewCut(
                    palette: cuts[index].palette,
                    center: cuts[index].center,
                    spaceName: cuts[index].spaceName,
                    day: cuts[index].day,
                    isVisited: isDoubleTapToVisitEnabled && index == 1,
                    showsColor: showsWebCut,
                    showsSpaceName: showsSpaceName,
                    showsDay: showsDay
                )
            }
        }
        .frame(maxWidth: 360.0)
        .frame(maxWidth: .infinity)
        .accessibilityHidden(true)
    }
}
