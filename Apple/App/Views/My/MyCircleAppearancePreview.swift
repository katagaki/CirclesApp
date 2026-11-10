import SwiftUI

struct MyCircleAppearancePreview: View {

    var showsWebCut: Bool
    var showsSpaceName: Bool
    var showsDay: Bool
    var isDoubleTapToVisitEnabled: Bool

    @AppStorage(wrappedValue: .medium, "Circles.GridSize") var displayMode: GridDisplayMode

    let cuts: [(palette: [Color], center: SIMD2<Float>, spaceName: String, day: Int)] = [
        ([.accentColor, .yellow, .pink, .purple], [0.3, 0.6], "東A01a", 1),
        ([.teal, .orange, .indigo, .mint], [0.7, 0.4], "東A02b", 1),
        ([.pink, .mint, .accentColor, .orange], [0.4, 0.3], "西あ12a", 2),
        ([.orange, .accentColor, .green, .yellow], [0.6, 0.7], "南c34b", 2),
        ([.purple, .cyan, .yellow, .accentColor], [0.5, 0.4], "東B05a", 1),
        ([.mint, .pink, .orange, .teal], [0.4, 0.6], "西い20b", 2)
    ]

    var cutWidth: CGFloat {
        let isPhone = UIDevice.current.userInterfaceIdiom == .phone
        switch displayMode {
        case .big: return isPhone ? 110.0 : 100.0
        case .medium: return isPhone ? 76.0 : 68.0
        case .small: return isPhone ? 48.0 : 44.0
        }
    }

    var cutCount: Int {
        switch displayMode {
        case .big: return 3
        case .medium: return 4
        case .small: return 6
        }
    }

    var body: some View {
        HStack(spacing: 1.0) {
            ForEach(0..<cutCount, id: \.self) { index in
                MyCircleAppearancePreviewCut(
                    palette: cuts[index].palette,
                    center: cuts[index].center,
                    spaceName: cuts[index].spaceName,
                    day: cuts[index].day,
                    pillSize: displayMode == .small ? .tiny : .small,
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
