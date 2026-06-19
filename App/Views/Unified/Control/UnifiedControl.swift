import SwiftData
import SwiftUI
import AXiS

struct UnifiedControl: View {
    @Environment(UserSelections.self) var selections

    var body: some View {
        Group {
            if selections.date != nil && selections.map != nil {
                HStack {
                    DatePicker()
                        .padding([.leading], 12.0)
                    Spacer()
                    HallPicker()
                        .background(accentColorForMap(selections.map))
                        .clipShape(.capsule)
                }
            }
        }
        .frame(minWidth: 100.0, maxWidth: 280.0)
        .padding(6.0)
        .phaseAnimator([1.0, 1.1, 1.0], trigger: selections.fullMapID) { content, scale in
            content
                .scaleEffect(scale)
        } animation: { _ in
            .smooth(duration: 0.2)
        }
    }

    func accentColorForMap(_ map: ComiketMap?) -> Color? {
        if let map {
            if map.name.starts(with: "東") {
                return Color.red
            } else if map.name.starts(with: "西") {
                return Color.blue
            } else if map.name.starts(with: "南") {
                return Color.green
            } else if map.name.starts(with: "会議") || map.name.starts(with: "会") {
                return Color.gray
            }
        }
        return Color.accentColor
    }
}
