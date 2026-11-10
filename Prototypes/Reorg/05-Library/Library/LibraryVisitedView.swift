import SwiftUI

struct LibraryVisitedView: View {

    @Environment(Harness.self) var harness

    var body: some View {
        List {
            Section("\(harness.visited.count) circles visited") {
                ForEach(MockData.circles.filter { harness.visited.contains($0.id) }) { circle in
                    NavigationLink(value: circle) {
                        CircleRow(circle: circle)
                    }
                }
            }
        }
    }
}
