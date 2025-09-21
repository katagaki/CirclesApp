//
//  MapControlStack.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2025/06/07.
//

import SwiftUI

struct MapControlStack: View {

    @Binding var showGenreOverlay: Bool
    @Binding var useDarkModeMaps: Bool
    @Binding var zoomDivisor: Int

    var body: some View {
        SquareButtonStack {
            Group {
                VStack(alignment: .center, spacing: 0.0) {
                    SquareButton {
                        withAnimation(.smooth.speed(2.0)) {
                            useDarkModeMaps.toggle()
                        }
                    } label: {
                        Image(systemName: useDarkModeMaps ?
                              "moon.fill" :
                                "sun.max")
                        .font(.title2)
                    }
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
                    SquareButton {
                        zoomDivisor += 1
                    } label: {
                        Image(systemName: "minus")
                            .font(.title)
                    }
                    .disabled(zoomDivisor >= 4)
                }
            }
            .clipShape(.capsule)
            .glassEffectIfSupported(bordered: true)
            .overlay {
                Capsule()
                    .stroke(.primary.opacity(0.2), lineWidth: 1 / 3)
            }
        }
    }
}
