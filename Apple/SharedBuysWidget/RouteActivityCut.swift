import ORBiT
import SwiftUI

struct RouteActivityCut: View {

    let circleID: Int
    let height: CGFloat

    var body: some View {
        Group {
            if let image = RouteCutStore.image(for: circleID) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
            } else {
                Rectangle()
                    .fill(.quaternary)
            }
        }
        .frame(width: height * 40.0 / 57.0, height: height)
    }
}
