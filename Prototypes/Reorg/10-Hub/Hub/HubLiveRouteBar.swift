import SwiftUI

struct HubLiveRouteBar: View {

    @Environment(Harness.self) var harness
    @Binding var path: NavigationPath

    var body: some View {
        if let stop = harness.nextStop {
            HStack(spacing: 10.0) {
                Button {
                    path.append(Feature.navigation)
                } label: {
                    HStack(spacing: 10.0) {
                        CircleCut(circle: stop, size: 26.0)
                        VStack(alignment: .leading, spacing: 1.0) {
                            Text("NEXT · \(harness.routeStep + 1) of \(harness.routeStops.count)")
                                .font(.caption2.weight(.heavy))
                                .foregroundStyle(.white.opacity(0.85))
                            Text("\(stop.spaceName)  \(stop.name)")
                                .font(.subheadline.weight(.semibold))
                                .lineLimit(1)
                        }
                        Spacer(minLength: 0.0)
                    }
                    .contentShape(.rect)
                }
                .buttonStyle(.plain)
                Button {
                    harness.visited.insert(stop.id)
                    harness.routeStep = min(harness.routeStep + 1, harness.routeStops.count - 1)
                } label: {
                    Image(systemName: "checkmark")
                        .font(.body.weight(.bold))
                        .frame(width: 34.0, height: 34.0)
                        .background(.white.opacity(0.25), in: .circle)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Mark Visited")
                Button {
                    withAnimation(.snappy) { harness.isNavigating = false }
                } label: {
                    Image(systemName: "xmark")
                        .font(.footnote.weight(.bold))
                        .frame(width: 34.0, height: 34.0)
                        .background(.white.opacity(0.25), in: .circle)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("End Route")
            }
            .foregroundStyle(.white)
            .padding(.leading, 12.0)
            .padding(.trailing, 8.0)
            .padding(.vertical, 8.0)
            .background(Color.blue.gradient, in: .rect(cornerRadius: 18.0))
        }
    }
}
