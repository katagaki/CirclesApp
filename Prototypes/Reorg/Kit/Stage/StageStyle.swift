import SwiftUI

enum StageStyle: Hashable {
    case sheet
    case panel

    static func style(for width: CGFloat) -> StageStyle {
        width >= 600.0 ? .panel : .sheet
    }
}

extension EnvironmentValues {
    @Entry var stageStyle: StageStyle = .sheet
    @Entry var stageSize: CGSize = .zero
}
