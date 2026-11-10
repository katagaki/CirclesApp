import SwiftUI

struct HarnessRoot<Content: View>: View {

    @State var harness = Harness()
    let content: () -> Content

    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    var body: some View {
        content()
            .environment(harness)
            .overlay(alignment: .top) {
                HarnessCapsule()
                    .environment(harness)
                    .offset(y: -16.0)
            }
    }
}
