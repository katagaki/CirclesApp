//
//  ImageCropView.swift
//  CiRCLES
//
//  Created by Claude on 2026/03/24.
//

import SwiftUI

struct ImageCropView: View {

    let image: UIImage
    let onCrop: (UIImage) -> Void
    let onCancel: () -> Void

    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    @State private var viewSize: CGSize = .zero

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                let cropSize = min(geometry.size.width, geometry.size.height) * 0.8
                ZStack {
                    Color.black
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .scaleEffect(scale)
                        .offset(offset)
                        .gesture(
                            SimultaneousGesture(
                                MagnifyGesture()
                                    .onChanged { value in
                                        scale = lastScale * value.magnification
                                    }
                                    .onEnded { _ in
                                        lastScale = max(1.0, scale)
                                        scale = lastScale
                                    },
                                DragGesture()
                                    .onChanged { value in
                                        offset = CGSize(
                                            width: lastOffset.width + value.translation.width,
                                            height: lastOffset.height + value.translation.height
                                        )
                                    }
                                    .onEnded { _ in
                                        lastOffset = offset
                                    }
                            )
                        )
                    Rectangle()
                        .fill(Color.black.opacity(0.5))
                        .mask {
                            ZStack {
                                Rectangle()
                                RoundedRectangle(cornerRadius: 4.0)
                                    .frame(width: cropSize, height: cropSize)
                                    .blendMode(.destinationOut)
                            }
                            .compositingGroup()
                        }
                        .allowsHitTesting(false)
                    RoundedRectangle(cornerRadius: 4.0)
                        .stroke(Color.white, lineWidth: 1.0)
                        .frame(width: cropSize, height: cropSize)
                        .allowsHitTesting(false)
                }
                .onAppear {
                    viewSize = geometry.size
                }
                .onChange(of: geometry.size) {
                    viewSize = geometry.size
                }
            }
            .ignoresSafeArea()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Shared.Cancel") {
                        onCancel()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Shared.Done") {
                        cropImage()
                    }
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
        }
    }

    private func cropImage() {
        let cropSize = min(viewSize.width, viewSize.height) * 0.8
        let renderScale = 300.0 / cropSize
        let scaledOffset = CGSize(
            width: offset.width * renderScale,
            height: offset.height * renderScale
        )
        let renderSize = CGSize(
            width: viewSize.width * renderScale,
            height: viewSize.height * renderScale
        )
        let renderer = ImageRenderer(content:
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .scaleEffect(scale)
                .offset(scaledOffset)
                .frame(width: renderSize.width, height: renderSize.height)
                .frame(width: 300, height: 300)
                .clipped()
        )
        renderer.scale = UIScreen.main.scale
        if let croppedUIImage = renderer.uiImage {
            onCrop(croppedUIImage)
        } else {
            onCrop(image)
        }
    }
}
