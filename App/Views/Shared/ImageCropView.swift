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
                                        scale = max(1.0, lastScale * value.magnification)
                                    }
                                    .onEnded { _ in
                                        lastScale = max(1.0, scale)
                                        scale = lastScale
                                        offset = clampedOffset(offset, viewSize: geometry.size, cropSize: cropSize)
                                        lastOffset = offset
                                    },
                                DragGesture()
                                    .onChanged { value in
                                        let proposed = CGSize(
                                            width: lastOffset.width + value.translation.width,
                                            height: lastOffset.height + value.translation.height
                                        )
                                        offset = clampedOffset(proposed, viewSize: geometry.size, cropSize: cropSize)
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
                    if #available(iOS 26.0, *) {
                        Button(role: .cancel) {
                            onCancel()
                        }
                    } else {
                        Button("Shared.Cancel") {
                            onCancel()
                        }
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    if #available(iOS 26, *) {
                        Button(role: .confirm) {
                            cropImage()
                        }
                    } else {
                        Button("Shared.Done") {
                            cropImage()
                        }
                    }
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
        }
    }

    private func clampedOffset(_ proposed: CGSize, viewSize: CGSize, cropSize: CGFloat) -> CGSize {
        let imageAspect = image.size.width / image.size.height
        let viewAspect = viewSize.width / viewSize.height

        let fittedSize: CGSize
        if imageAspect > viewAspect {
            let width = viewSize.width
            let height = width / imageAspect
            fittedSize = CGSize(width: width, height: height)
        } else {
            let height = viewSize.height
            let width = height * imageAspect
            fittedSize = CGSize(width: width, height: height)
        }

        let scaledWidth = fittedSize.width * scale
        let scaledHeight = fittedSize.height * scale

        let maxOffsetX = max(0, (scaledWidth - cropSize) / 2.0)
        let maxOffsetY = max(0, (scaledHeight - cropSize) / 2.0)

        return CGSize(
            width: min(maxOffsetX, max(-maxOffsetX, proposed.width)),
            height: min(maxOffsetY, max(-maxOffsetY, proposed.height))
        )
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
