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
            HStack(alignment: .center, spacing: 0.0) {
                SquareButton {
                    zoomDivisor += 1
                } label: {
                    Image(systemName: "minus")
                        .font(.title)
                }
                .disabled(zoomDivisor >= 4)
                SquareButton {
                    zoomDivisor -= 1
                } label: {
                    Image(systemName: "plus")
                        .font(.title)
                }
                .disabled(zoomDivisor <= 1)
            }
            .clipShape(.capsule)
            .glassEffectIfSupported(bordered: true)
            .overlay {
                if #unavailable(iOS 26.0) {
                    Capsule()
                        .stroke(.primary.opacity(0.2), lineWidth: 1 / 3)
                }
            }
        }
    }
}
