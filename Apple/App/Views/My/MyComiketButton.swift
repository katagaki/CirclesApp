import SwiftUI

struct MyComiketButton: View {

    @Environment(Unifier.self) var unifier

    var body: some View {
        Button {
            unifier.isMyComiketPresenting = true
        } label: {
            MyProfilePhoto()
                .frame(width: 38.0, height: 38.0)
                .padding(3.0)
                .glassEffect(.regular.interactive(), in: .circle)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("ViewTitle.My")
    }
}
