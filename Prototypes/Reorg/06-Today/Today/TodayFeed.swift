import SwiftUI

struct TodayFeed: View {

    @Environment(Harness.self) var harness
    var isCompact: Bool = false

    var kinds: [TodayCardKind] {
        let ordered = TodayCardKind.ordered(for: harness)
        return isCompact ? Array(ordered.prefix(1)) : ordered
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 12.0) {
                ForEach(kinds) { kind in
                    TodayCardView(kind: kind)
                }
            }
            .padding(.horizontal, 16.0)
            .padding(.top, 6.0)
            .padding(.bottom, 16.0)
            .animation(.default, value: kinds.map(\.id))
        }
    }
}
