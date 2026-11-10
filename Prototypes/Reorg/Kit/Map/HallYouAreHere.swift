import SwiftUI

struct HallYouAreHere: View {

    var body: some View {
        Circle()
            .fill(.blue)
            .frame(width: 14.0, height: 14.0)
            .overlay(Circle().stroke(.white, lineWidth: 3.0))
            .background(Circle().fill(.blue.opacity(0.2)).frame(width: 40.0, height: 40.0))
            .shadow(radius: 2.0)
    }
}
