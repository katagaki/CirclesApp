import SwiftUI

struct FocusMapView: View {

    @Environment(CatalogStore.self) private var store

    let favorite: Favorite

    @State private var visibleWidth: Double = 240.0
    @FocusState private var isCrownFocused: Bool

    var body: some View {
        GeometryReader { proxy in
            if let image = store.mapImage(mapID: favorite.mapID, day: favorite.circle.day),
               let rect = store.rect(for: favorite.circle) {
                let scale = proxy.size.width / CGFloat(visibleWidth)
                MapCanvas(
                    image: image,
                    markers: neighbourMarkers(excluding: favorite.circle.id),
                    focusRect: rect,
                    scale: scale,
                    center: CGPoint(x: rect.midX, y: rect.midY)
                )
                .overlay(alignment: .bottom) {
                    caption
                }
                .focusable()
                .focused($isCrownFocused)
                .digitalCrownRotation(
                    $visibleWidth,
                    from: 120.0,
                    through: Double(image.size.width),
                    by: 20.0,
                    sensitivity: .medium,
                    isContinuous: false,
                    isHapticFeedbackEnabled: true
                )
                .onAppear { isCrownFocused = true }
            } else {
                ContentUnavailableView("No map", systemImage: "map")
            }
        }
        .ignoresSafeArea(edges: .bottom)
    }

    private var caption: some View {
        VStack(spacing: 1.0) {
            Text(favorite.spaceLabel)
                .font(.system(.title3, design: .rounded, weight: .bold))
            Text(store.map(id: favorite.mapID)?.name ?? "")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 8.0)
        .padding(.vertical, 3.0)
        .background(.black.opacity(0.65), in: Capsule())
        .padding(.bottom, 4.0)
    }

    private func neighbourMarkers(excluding circleID: Int) -> [MapMarker] {
        store.favorites(inMap: favorite.mapID, on: favorite.circle.day)
            .filter { $0.circle.id != circleID }
            .compactMap { other in
                guard let rect = store.rect(for: other.circle) else { return nil }
                return MapMarker(id: other.circle.id, rect: rect, color: other.color.color)
            }
    }
}
