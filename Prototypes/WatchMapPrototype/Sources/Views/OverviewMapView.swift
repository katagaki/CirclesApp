import SwiftUI

struct OverviewMapView: View {

    @Environment(CatalogStore.self) private var store

    let favorite: Favorite

    @State private var selectionIndex: Double = 0.0
    @State private var hasAligned: Bool = false
    @FocusState private var isCrownFocused: Bool

    private var siblings: [Favorite] {
        store.favorites(inMap: favorite.mapID, on: favorite.circle.day)
    }

    private var selected: Favorite? {
        let list = siblings
        guard !list.isEmpty else { return nil }
        let index = min(max(Int(selectionIndex.rounded()), 0), list.count - 1)
        return list[index]
    }

    var body: some View {
        GeometryReader { proxy in
            if let image = store.mapImage(mapID: favorite.mapID, day: favorite.circle.day) {
                let scale = min(
                    proxy.size.width / image.size.width,
                    proxy.size.height / image.size.height
                )
                let target = selected.flatMap { store.rect(for: $0.circle) }
                MapCanvas(
                    image: image,
                    markers: dotMarkers(),
                    focusRect: target,
                    scale: scale,
                    center: CGPoint(x: image.size.width / 2.0, y: image.size.height / 2.0),
                    markerMinimumSize: 7.0,
                    drawsMarkersAsDots: true
                )
                .overlay(alignment: .bottom) { caption }
                .focusable()
                .focused($isCrownFocused)
                .digitalCrownRotation(
                    $selectionIndex,
                    from: 0.0,
                    through: Double(max(siblings.count - 1, 0)),
                    by: 1.0,
                    sensitivity: .low,
                    isContinuous: false,
                    isHapticFeedbackEnabled: true
                )
                .onAppear {
                    isCrownFocused = true
                    if !hasAligned {
                        hasAligned = true
                        if let index = siblings.firstIndex(where: { $0.id == favorite.id }) {
                            selectionIndex = Double(index)
                        }
                    }
                }
            } else {
                ContentUnavailableView("No map", systemImage: "map")
            }
        }
        .ignoresSafeArea(edges: .bottom)
    }

    @ViewBuilder
    private var caption: some View {
        if let selected {
            VStack(spacing: 1.0) {
                Text(selected.spaceLabel)
                    .font(.system(.headline, design: .rounded, weight: .bold))
                Text(selected.circle.name)
                    .font(.caption2)
                    .lineLimit(1)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 8.0)
            .padding(.vertical, 3.0)
            .background(.black.opacity(0.65), in: Capsule())
            .padding(.bottom, 4.0)
        }
    }

    private func dotMarkers() -> [MapMarker] {
        siblings.compactMap { item in
            guard let rect = store.rect(for: item.circle) else { return nil }
            return MapMarker(id: item.circle.id, rect: rect, color: item.color.color)
        }
    }
}
