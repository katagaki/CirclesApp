import SwiftData
import SwiftUI
import AXiS

struct UnifiedControl: View {
    @Environment(UserSelections.self) var selections
    @Environment(Unifier.self) var unifier

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
        .background {
            GeometryReader { proxy in
                Color.clear
                    .onAppear { updateControlFrame(proxy.frame(in: .global)) }
                    .onChange(of: proxy.frame(in: .global)) { _, newValue in
                        updateControlFrame(newValue)
                    }
            }
        }
        .opacity(unifier.presentedControlMenu == nil ? 1.0 : 0.0)
    }

    // The control is hidden while a menu is open, so keep the anchor from drifting.
    func updateControlFrame(_ frame: CGRect) {
        guard unifier.presentedControlMenu == nil else { return }
        unifier.controlFrame = frame
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
