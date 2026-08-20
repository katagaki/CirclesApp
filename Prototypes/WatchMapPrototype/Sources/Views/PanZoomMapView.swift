import SwiftUI

struct PanZoomMapView: View {

    @Environment(CatalogStore.self) private var store

    let favorite: Favorite

    @State private var visibleWidth: Double = 400.0
    @State private var center: CGPoint = .zero
    @State private var hasCentered: Bool = false
    @GestureState private var dragTranslation: CGSize = .zero
    @FocusState private var isCrownFocused: Bool

    var body: some View {
        GeometryReader { proxy in
            if let image = store.mapImage(mapID: favorite.mapID, day: favorite.circle.day),
               let rect = store.rect(for: favorite.circle) {
                let scale = proxy.size.width / CGFloat(visibleWidth)
                let liveCenter = clamped(
                    CGPoint(
                        x: center.x - dragTranslation.width / scale,
                        y: center.y - dragTranslation.height / scale
                    ),
                    imageSize: image.size
                )
                MapCanvas(
                    image: image,
                    markers: allMarkers(),
                    focusRect: rect,
                    scale: scale,
                    center: liveCenter
                )
                .contentShape(Rectangle())
                .gesture(
                    DragGesture()
                        .updating($dragTranslation) { value, state, _ in
                            state = value.translation
                        }
                        .onEnded { value in
                            center = clamped(
                                CGPoint(
                                    x: center.x - value.translation.width / scale,
                                    y: center.y - value.translation.height / scale
                                ),
                                imageSize: image.size
                            )
                        }
                )
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
                .overlay(alignment: .topTrailing) {
                    recenterButton(rect: rect)
                }
                .onAppear {
                    isCrownFocused = true
                    if !hasCentered {
                        hasCentered = true
                        center = CGPoint(x: rect.midX, y: rect.midY)
                    }
                }
            } else {
                ContentUnavailableView("No map", systemImage: "map")
            }
        }
        .ignoresSafeArea(edges: .bottom)
    }

    private func recenterButton(rect: CGRect) -> some View {
        Button {
            withAnimation(.snappy) {
                center = CGPoint(x: rect.midX, y: rect.midY)
                visibleWidth = 240.0
            }
        } label: {
            Image(systemName: "scope")
                .font(.system(size: 17.0, weight: .semibold))
        }
        .buttonStyle(.glass)
        .padding(4.0)
    }

    private func clamped(_ point: CGPoint, imageSize: CGSize) -> CGPoint {
        CGPoint(
            x: min(max(point.x, 0.0), imageSize.width),
            y: min(max(point.y, 0.0), imageSize.height)
        )
    }

    private func allMarkers() -> [MapMarker] {
        store.favorites(inMap: favorite.mapID, on: favorite.circle.day)
            .filter { $0.circle.id != favorite.circle.id }
            .compactMap { other in
                guard let rect = store.rect(for: other.circle) else { return nil }
                return MapMarker(id: other.circle.id, rect: rect, color: other.color.color)
            }
    }
}
