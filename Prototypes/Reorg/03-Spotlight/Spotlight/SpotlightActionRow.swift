import SwiftUI

struct SpotlightActionRow: View {

    let action: SpotlightAction
    @Binding var path: NavigationPath

    var body: some View {
        Button {
            action.perform()
            if let destination = action.destination {
                path.append(destination)
            }
        } label: {
            HStack {
                SpotlightRowLabel(title: action.title, subtitle: action.subtitle, symbol: action.symbol, tint: action.tint)
                Spacer(minLength: 0.0)
                Image(systemName: action.destination == nil ? "return" : "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }
}
