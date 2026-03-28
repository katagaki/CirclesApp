//
//  BuyItemImageViewer.swift
//  CiRCLES
//
//  Created by Claude on 2026/03/28.
//

import SwiftUI

struct BuyItemImageViewer: View {

    @Environment(\.dismiss) var dismiss

    let image: UIImage

    @State var currentScale: CGFloat = 1.0
    @State var anchor: UnitPoint = .center

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .scaleEffect(currentScale, anchor: anchor)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .gesture(
                        MagnifyGesture()
                            .onChanged { value in
                                currentScale = value.magnification
                                anchor = value.startAnchor
                            }
                            .onEnded { _ in
                                withAnimation(.smooth.speed(2.0)) {
                                    currentScale = 1.0
                                }
                            }
                    )
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Shared.Back", systemImage: "chevron.left") {
                        dismiss()
                    }
                }
            }
        }
    }
}
