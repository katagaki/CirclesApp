import SwiftUI

struct CircleGrid: View {

    let circles: [MockCircle]
    var minimumWidth: CGFloat = 76.0

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: minimumWidth), spacing: 10.0)], spacing: 12.0) {
            ForEach(circles) { circle in
                NavigationLink(value: circle) {
                    CircleGridCell(circle: circle)
                }
                .buttonStyle(.plain)
            }
        }
    }
}
