//
//  CircleMapView.swift
//  OnHand
//
//  Created by シン・ジャスティン on 2026/08/26.
//

import SwiftUI

struct CircleMapView: View {

    @Environment(OnHandStore.self) var store

    let circleID: Int

    @State var image: UIImage?
    @State var zoom: Double = 1.0
    @State var pan: CGSize = .zero
    @State var panWhenDragStarted: CGSize = .zero
    @State var isPanning: Bool = false

    var favorite: OnHandFavorite? {
        store.payload.favorites.first { $0.id == circleID }
    }

    var neighbours: [OnHandFavorite] {
        guard let favorite else { return [] }
        return store.payload.favorites.filter {
            $0.mapKey == favorite.mapKey && $0.mapRect != nil && $0.id != circleID
        }
    }

    var body: some View {
        Group {
            if let image, let favorite, let rect = favorite.mapRect {
                map(image: image, favorite: favorite, rect: rect)
            } else {
                ContentUnavailableView(
                    "OnHand.Map.Unavailable",
                    systemImage: "map",
                    description: Text("OnHand.Map.Unavailable.Description")
                )
            }
        }
        .navigationTitle(favorite?.hallName ?? "")
        .navigationBarTitleDisplayMode(.inline)
        .task(id: store.assetsVersion) {
            await load()
        }
    }

    func map(image: UIImage, favorite: OnHandFavorite, rect: OnHandRect) -> some View {
        GeometryReader { proxy in
            let layout = MapLayout(
                imageSize: image.size,
                viewport: proxy.size,
                target: rect,
                zoom: zoom
            )
            let offset = isPanning ? layout.clamped(pan) : layout.centeringOffset

            ZStack(alignment: .topLeading) {
                Image(uiImage: image)
                    .resizable()
                    .frame(width: layout.content.width, height: layout.content.height)

                ForEach(neighbours) { neighbour in
                    if let neighbourRect = neighbour.mapRect {
                        marker(
                            color: OnHandColor(value: neighbour.colorValue).background,
                            isVisited: neighbour.isVisited,
                            in: neighbourRect,
                            layout: layout
                        )
                    }
                }

                marker(color: .red, isVisited: false, in: rect, layout: layout)

                Circle()
                    .stroke(Color.red, lineWidth: 2.0)
                    .frame(width: 22.0, height: 22.0)
                    .offset(
                        x: rect.midX * layout.content.width - 11.0,
                        y: rect.midY * layout.content.height - 11.0
                    )
            }
            .frame(width: layout.content.width, height: layout.content.height, alignment: .topLeading)
            .offset(x: offset.width, y: offset.height)
            .frame(width: proxy.size.width, height: proxy.size.height, alignment: .topLeading)
            .clipped()
            .contentShape(.rect)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        if !isPanning {
                            isPanning = true
                            panWhenDragStarted = layout.centeringOffset
                        }
                        pan = CGSize(
                            width: panWhenDragStarted.width + value.translation.width,
                            height: panWhenDragStarted.height + value.translation.height
                        )
                    }
            )
        }
        .focusable()
        .digitalCrownRotation(
            $zoom,
            from: 0.0,
            through: 1.0,
            by: 0.05,
            sensitivity: .low,
            isContinuous: false,
            isHapticFeedbackEnabled: true
        )
        .onChange(of: zoom) {
            isPanning = false
        }
        .safeAreaInset(edge: .bottom) {
            HStack(spacing: 4.0) {
                SpacePill(
                    label: favorite.spaceLabel,
                    color: OnHandColor(value: favorite.colorValue),
                    fontSize: 14.0
                )
                HallBadge(name: favorite.hallName, filename: favorite.hallFilename, fontSize: 12.0)
            }
            .padding(.bottom, 2.0)
        }
    }

    func marker(color: Color, isVisited: Bool, in rect: OnHandRect, layout: MapLayout) -> some View {
        Rectangle()
            .fill(color.opacity(isVisited ? 0.3 : 0.75))
            .frame(
                width: max(3.0, rect.width * layout.content.width),
                height: max(3.0, rect.height * layout.content.height)
            )
            .offset(x: rect.originX * layout.content.width, y: rect.originY * layout.content.height)
    }

    func load() async {
        guard let mapKey = favorite?.mapKey else { return }
        let url = OnHandAssets.mapURL(forKey: mapKey)
        image = await Task.detached(priority: .userInitiated) {
            OnHandAssets.image(at: url)
        }.value
    }
}

struct MapLayout {

    let content: CGSize
    let viewport: CGSize
    let target: OnHandRect

    init(imageSize: CGSize, viewport: CGSize, target: OnHandRect, zoom: Double) {
        self.viewport = viewport
        self.target = target

        guard viewport.width > 0.0, viewport.height > 0.0,
              imageSize.width > 0.0, imageSize.height > 0.0 else {
            content = .zero
            return
        }

        let fitScale = min(viewport.width / imageSize.width, viewport.height / imageSize.height)
        let readableScale = max(fitScale, 40.0 / max(1.0, target.width * imageSize.width))
        let scale = fitScale * pow(readableScale / fitScale, max(0.0, min(1.0, zoom)))

        content = CGSize(width: imageSize.width * scale, height: imageSize.height * scale)
    }

    var centeringOffset: CGSize {
        clamped(CGSize(
            width: viewport.width / 2.0 - target.midX * content.width,
            height: viewport.height / 2.0 - target.midY * content.height
        ))
    }

    func clamped(_ offset: CGSize) -> CGSize {
        CGSize(
            width: clamp(offset.width, span: content.width, within: viewport.width),
            height: clamp(offset.height, span: content.height, within: viewport.height)
        )
    }

    private func clamp(_ value: CGFloat, span: CGFloat, within available: CGFloat) -> CGFloat {
        guard span > available else { return (available - span) / 2.0 }
        return min(0.0, max(available - span, value))
    }
}
