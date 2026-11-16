import SwiftUI
import AXiS

/// A list row that cross-fades between its compact and regular layouts during a pinch.
struct PinchZoomListRow: View {

    var circle: ComiketCircle
    var namespace: Namespace.ID
    var regularWeight: CGFloat
    var dividerLeading: CGFloat
    var background: AnyShapeStyle?

    var body: some View {
        VStack(spacing: 0.0) {
            ZStack(alignment: .topLeading) {
                CircleListCompactRow(circle: circle, namespace: namespace)
                    .padding([.leading, .trailing], 20.0)
                    .padding([.top, .bottom], 10.0)
                    .opacity(1.0 - regularWeight)
                CircleListRegularRow(circle: circle, namespace: namespace)
                    .padding([.leading, .trailing], 20.0)
                    .padding([.top, .bottom], 10.0)
                    .opacity(regularWeight)
            }
            .frame(maxHeight: .infinity, alignment: .top)
            .clipped()
            Divider()
                .padding([.leading], dividerLeading)
        }
        .background(background ?? AnyShapeStyle(.clear))
    }
}
