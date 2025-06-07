//
//  MapControlStack.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2025/06/07.
//

import SwiftUI

struct MapControlStack: View {

    @Binding var showGenreOverlay: Bool
    @Binding var zoomDivisor: Int

    var body: some View {
        SquareButtonStack {
            VStack(alignment: .center, spacing: 0.0) {
                SquareButton {
                    withAnimation(.smooth.speed(2.0)) {
                        showGenreOverlay.toggle()
                    }
                } label: {
                    Image(systemName: showGenreOverlay ?
                          "theatermask.and.paintbrush.fill" :
                            "theatermask.and.paintbrush")
                    .font(.title2)
                }
                .popoverTip(GenreOverlayTip())
            }
            VStack(alignment: .center, spacing: 0.0) {
                SquareButton {
                    zoomDivisor -= 1
                } label: {
                    Image(systemName: "plus")
                        .font(.title)
                }
                .disabled(zoomDivisor <= 1)
                Divider()
                SquareButton {
                    zoomDivisor += 1
                } label: {
                    Image(systemName: "minus")
                        .font(.title)
                }
                .disabled(zoomDivisor >= 4)
            }
        }
    }
}
