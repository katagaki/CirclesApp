import SwiftUI

struct ModeSwitchLabelStyle: LabelStyle {

    let isSelected: Bool

    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 5.0) {
            if isSelected {
                configuration.icon
            }
            configuration.title
        }
    }
}
