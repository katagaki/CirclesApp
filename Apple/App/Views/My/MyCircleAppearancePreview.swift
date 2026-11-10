import SwiftUI

struct MyCircleAppearancePreview: View {

    var showsWebCut: Bool
    var showsSpaceName: Bool
    var showsDay: Bool
    var isDoubleTapToVisitEnabled: Bool

    let cuts: [(palette: [Color], spaceName: String, day: Int)] = [
        ([.accentColor, .yellow, .pink], "東A01a", 1),
        ([.teal, .orange, .indigo], "東A02b", 1),
        ([.pink, .mint, .accentColor], "西あ12a", 2),
        ([.orange, .accentColor, .green], "南c34b", 2)
    ]

    var body: some View {
        HStack(spacing: 1.0) {
            ForEach(cuts.indices, id: \.self) { index in
                MyCircleAppearancePreviewCut(
                    palette: cuts[index].palette,
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
