import SwiftUI

struct MapRouteLayer: View {

    @Environment(Mapper.self) var mapper
    @Environment(Navigator.self) var navigator

    let spaceSize: Int

    var scale: CGFloat {
        CGFloat(spaceSize) / Navigator.planningSpaceSize
    }

    var lineWidth: CGFloat {
        CGFloat(spaceSize) * 0.22
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            if let route = navigator.route {
                let currentStop = navigator.currentStep?.stopIndex ?? 0
                ForEach(Array(route.legs.enumerated()), id: \.offset) { index, leg in
                    polyline(leg)
                        .stroke(
                            index < currentStop ? Color.secondary.opacity(0.45) : Color.accentColor.opacity(0.35),
                            style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round)
                        )
                }
                if route.legs.indices.contains(currentStop) {
                    polyline(route.legs[currentStop])
                        .stroke(.white, style: StrokeStyle(lineWidth: lineWidth * 1.9, lineCap: .round, lineJoin: .round))
                        .shadow(color: .black.opacity(0.25), radius: 3.0)
                    polyline(route.legs[currentStop])
                        .stroke(Color.accentColor, style: StrokeStyle(lineWidth: lineWidth * 1.2, lineCap: .round, lineJoin: .round))
                }
                if let step = navigator.currentStep {
                    polyline(step.path)
                        .stroke(.white, style: StrokeStyle(lineWidth: lineWidth * 0.45, lineCap: .round, lineJoin: .round,
                                                           dash: [lineWidth * 0.2, lineWidth * 0.9]))
                }
                ForEach(Array(route.outsidePaths.enumerated()), id: \.offset) { _, walk in
                    polyline(walk)
                        .stroke(Color.accentColor, style: StrokeStyle(lineWidth: lineWidth * 0.9, lineCap: .round,
                                                                 lineJoin: .round, dash: [lineWidth * 0.3, lineWidth * 1.2]))
                }
                ForEach(Array(route.stops.enumerated()), id: \.element.id) { index, stop in
                    MapRouteStopBadge(
                        number: index + 1,
                        state: index < currentStop ? .done : (index == currentStop ? .current : .upcoming),
                        size: CGFloat(spaceSize) * (index == currentStop ? 0.95 : 0.7)
                    )
                    .position(scaled(stop.accessPoint))
                }
            }
            ForEach(navigator.closureLines, id: \.id) { closure in
                polyline([closure.from, closure.to])
                    .stroke(Color.primary, style: StrokeStyle(lineWidth: lineWidth * 0.7, lineCap: .round,
                                                          dash: [lineWidth * 0.8, lineWidth * 0.6]))
            }
            if let line = navigator.pendingClosureLine {
                polyline([line.from, line.to])
                    .stroke(Color.primary.opacity(0.5), style: StrokeStyle(lineWidth: lineWidth * 0.7, lineCap: .round,
                                                                       dash: [lineWidth * 0.8, lineWidth * 0.6]))
            }
            ForEach(navigator.activeClosures) { closure in
                MapRouteClosureBadge(
                    size: CGFloat(spaceSize) * 0.85,
                    isSelected: navigator.selectedClosureID == closure.id
                )
                .position(scaled(closure.point))
            }
            if let pendingPoint = navigator.pendingPoint {
                MapRouteHoldMarker(size: CGFloat(spaceSize) * 0.8)
                    .position(scaled(pendingPoint))
            }
            if let origin = navigator.origin {
                MapRouteOriginPin(size: CGFloat(spaceSize) * 0.8)
                    .position(scaled(origin))
            }
        }
        .frame(width: mapper.canvasSize.width, height: mapper.canvasSize.height, alignment: .topLeading)
        .allowsHitTesting(false)
    }

    func scaled(_ point: CGPoint) -> CGPoint {
        CGPoint(x: point.x * scale, y: point.y * scale)
    }

    func polyline(_ points: [CGPoint]) -> Path {
        Path { path in
            guard let first = points.first else { return }
            path.move(to: scaled(first))
            for point in points.dropFirst() {
                path.addLine(to: scaled(point))
            }
        }
    }
}
