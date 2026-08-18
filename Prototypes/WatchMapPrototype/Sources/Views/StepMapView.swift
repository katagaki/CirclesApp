import SwiftUI
import WatchKit

struct StepMapView: View {

    @Environment(CatalogStore.self) private var store

    let favorite: Favorite

    @State private var mapID: Int = 0
    @State private var dayID: Int = 0
    @State private var selectionIndex: Double = 0.0
    @State private var tappedCircle: CatalogCircle?
    @State private var hasAligned: Bool = false
    @State private var isPickingMap: Bool = false
    @State private var visibleWidth: Double = 260.0
    @FocusState private var isCrownFocused: Bool

    private var siblings: [Favorite] {
        store.favorites(inMap: mapID, on: dayID)
    }

    private var stepIndex: Int {
        min(max(Int(selectionIndex.rounded()), 0), max(siblings.count - 1, 0))
    }

    private var selectedCircle: CatalogCircle? {
        if let tappedCircle { return tappedCircle }
        guard !siblings.isEmpty else { return nil }
        return siblings[stepIndex].circle
    }

    var body: some View {
        GeometryReader { proxy in
            if let image = store.mapImage(mapID: mapID, day: dayID) {
                let focusRect = selectedCircle.flatMap { store.rect(for: $0) }
                let center = focusRect.map { CGPoint(x: $0.midX, y: $0.midY) }
                    ?? CGPoint(x: image.size.width / 2.0, y: image.size.height / 2.0)
                let scale = proxy.size.width / CGFloat(visibleWidth)

                MapCanvas(
                    image: image,
                    markers: markers(excluding: selectedCircle?.id),
                    focusRect: focusRect,
                    scale: scale,
                    center: center
                )
                .animation(.snappy(duration: 0.25), value: center)
                .contentShape(Rectangle())
                .gesture(
                    SpatialTapGesture()
                        .onEnded { value in
                            handleTap(
                                at: value.location,
                                viewSize: proxy.size,
                                scale: scale,
                                center: center
                            )
                        }
                )
                .overlay(alignment: .top) { scrim(isTop: true).allowsHitTesting(false) }
                .overlay(alignment: .bottom) { scrim(isTop: false).allowsHitTesting(false) }
                .overlay(alignment: .topLeading) { mapButton }
                .overlay(alignment: .topTrailing) { counter }
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
                .onChange(of: stepIndex) {
                    tappedCircle = nil
                }
            } else {
                ContentUnavailableView("No map", systemImage: "map")
            }
        }
        .ignoresSafeArea()
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $isPickingMap) { mapPicker }
        .onAppear {
            isCrownFocused = true
            if !hasAligned {
                hasAligned = true
                mapID = favorite.mapID
                dayID = favorite.circle.day
                let seed = UserDefaults.standard.string(forKey: "Prototype.StepIndex")
                    .flatMap { Int($0) }
                if let seed {
                    selectionIndex = Double(min(seed, max(siblings.count - 1, 0)))
                } else if let index = siblings.firstIndex(where: { $0.id == favorite.id }) {
                    selectionIndex = Double(index)
                }
                isPickingMap = UserDefaults.standard.bool(forKey: "Prototype.ShowMapPicker")
            }
        }
    }

    private var mapButton: some View {
        Button {
            isPickingMap = true
        } label: {
            HStack(spacing: 2.0) {
                Text(store.map(id: mapID)?.name ?? "-")
                    .font(.system(size: 13.0, weight: .semibold))
                Image(systemName: "chevron.down")
                    .font(.system(size: 8.0, weight: .bold))
            }
            .foregroundStyle(Color.accentColor)
            .padding(.horizontal, 8.0)
            .padding(.vertical, 4.0)
            .background(.black.opacity(0.55), in: Capsule())
        }
        .buttonStyle(.plain)
        .padding(.leading, 8.0)
        .padding(.top, 6.0)
    }

    private var counter: some View {
        Text(siblings.isEmpty ? "0" : "\(stepIndex + 1)/\(siblings.count)")
            .font(.system(size: 12.0, weight: .medium))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 7.0)
            .padding(.vertical, 4.0)
            .background(.white.opacity(0.15), in: Capsule())
            .padding(.trailing, 8.0)
            .padding(.top, 6.0)
    }

    @ViewBuilder
    private var caption: some View {
        if let circle = selectedCircle {
            let matched = store.favorite(forCircle: circle.id)
            VStack(spacing: 1.0) {
                HStack(spacing: 4.0) {
                    if let matched {
                        Circle()
                            .fill(matched.color.color)
                            .frame(width: 8.0, height: 8.0)
                    }
                    Text("\(store.blockName(circle.blockID))\(circle.spaceNumberCombined)")
                        .font(.system(.title3, design: .rounded, weight: .bold))
                        .foregroundStyle(.primary)
                }
                Text(circle.name)
                    .font(.caption2)
                    .lineLimit(1)
                    .foregroundStyle(.secondary)
            }
            .padding(.bottom, 8.0)
        } else {
            Text("No favorites here")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.bottom, 8.0)
        }
    }

    private var mapPicker: some View {
        NavigationStack {
            List {
                ForEach(store.days) { day in
                    Section(day.shortLabel) {
                        ForEach(store.maps) { map in
                            Button {
                                select(mapID: map.id, dayID: day.id)
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 0.0) {
                                        Text(map.name)
                                        Text("\(store.favorites(inMap: map.id, on: day.id).count) favorites")
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    if map.id == mapID && day.id == dayID {
                                        Image(systemName: "checkmark")
                                            .foregroundStyle(Color.accentColor)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .navigationTitle("Map")
        }
    }

    private func select(mapID newMapID: Int, dayID newDayID: Int) {
        mapID = newMapID
        dayID = newDayID
        tappedCircle = nil
        selectionIndex = 0.0
        isPickingMap = false
        isCrownFocused = true
    }

    private func scrim(isTop: Bool) -> some View {
        LinearGradient(
            colors: [.black.opacity(0.85), .clear],
            startPoint: isTop ? .top : .bottom,
            endPoint: isTop ? .bottom : .top
        )
        .frame(height: isTop ? 44.0 : 58.0)
    }

    private func handleTap(at location: CGPoint, viewSize: CGSize, scale: CGFloat, center: CGPoint) {
        let mapPoint = CGPoint(
            x: (location.x - viewSize.width / 2.0) / scale + center.x,
            y: (location.y - viewSize.height / 2.0) / scale + center.y
        )
        guard let circle = store.circle(at: mapPoint, mapID: mapID, on: dayID) else { return }

        WKInterfaceDevice.current().play(.click)

        if let index = siblings.firstIndex(where: { $0.circle.id == circle.id }) {
            tappedCircle = nil
            selectionIndex = Double(index)
        } else {
            tappedCircle = circle
        }
    }

    private func markers(excluding circleID: Int?) -> [MapMarker] {
        siblings
            .filter { $0.circle.id != circleID }
            .compactMap { other in
                guard let rect = store.rect(for: other.circle) else { return nil }
                return MapMarker(id: other.circle.id, rect: rect, color: other.color.color)
            }
    }
}
