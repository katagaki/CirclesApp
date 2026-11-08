import ORBiT
import SwiftUI

struct RouteActivityCut: View {

    let circleID: Int

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
        .aspectRatio(40.0 / 57.0, contentMode: .fit)
    }
}
