//
//  AssetImage.swift
//  OnHand
//
//  Created by シン・ジャスティン on 2026/08/25.
//

import SwiftUI

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
