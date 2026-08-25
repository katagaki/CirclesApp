//
//  AssetImage.swift
//  OnHand
//
//  Created by シン・ジャスティン on 2026/08/25.
//

import SwiftUI
import WatchKit

struct AssetImage<Placeholder: View>: View {

    @Environment(OnHandStore.self) var store

    let url: () -> URL?
    @ViewBuilder let placeholder: () -> Placeholder

    @State var image: UIImage?

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
            } else {
                placeholder()
            }
        }
        .task(id: store.assetsVersion) {
            await load()
        }
    }

    func load() async {
        let url = url()
        let loaded = await Task.detached(priority: .userInitiated) {
            OnHandAssets.image(at: url)
        }.value
        image = loaded
    }
}

struct CircleCutImage: View {

    let circleID: Int

    var body: some View {
        AssetImage {
            OnHandAssets.circleCutURL(for: circleID)
        } placeholder: {
            RoundedRectangle(cornerRadius: 4.0)
                .fill(.quaternary)
                .aspectRatio(0.7, contentMode: .fit)
        }
        .clipShape(.rect(cornerRadius: 4.0))
    }
}

struct CircleMapView: View {

    @Environment(OnHandStore.self) var store

    let circleID: Int

    @State var zoomScale: CGFloat = 1.0

    var favorite: OnHandFavorite? {
        store.payload.favorites.first { $0.id == circleID }
    }

    var side: CGFloat {
        WKInterfaceDevice.current().screenBounds.width
    }

    var body: some View {
        ScrollView([.horizontal, .vertical]) {
            AssetImage {
                OnHandAssets.mapURL(for: circleID)
            } placeholder: {
                ContentUnavailableView(
                    "OnHand.Map.Unavailable",
                    systemImage: "map",
                    description: Text("OnHand.Map.Unavailable.Description")
                )
            }
            .frame(width: side * zoomScale, height: side * zoomScale)
        }
        .focusable()
        .digitalCrownRotation(
            $zoomScale,
            from: 1.0,
            through: 3.0,
            by: 0.1,
            sensitivity: .low,
            isContinuous: false,
            isHapticFeedbackEnabled: true
        )
        .safeAreaInset(edge: .bottom) {
            if let favorite {
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
        .navigationTitle("OnHand.Map")
        .navigationBarTitleDisplayMode(.inline)
    }
}
