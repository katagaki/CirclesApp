import SwiftUI

struct LayersVisitedList: View {

    @Environment(Harness.self) var harness

    var body: some View {
        List {
            Section("\(harness.visited.count) visited") {
                ForEach(MockData.circles.filter { harness.visited.contains($0.id) }) { circle in
                    NavigationLink(value: circle) {
                        CircleRow(circle: circle)
                    }
                }
            }
            Section("Still to visit") {
                ForEach(harness.favoriteCircles.filter { !harness.visited.contains($0.id) }) { circle in
                    NavigationLink(value: circle) {
                        CircleRow(circle: circle)
                    }
                }
            }
        }
    }
}
