//
//  MapHighlightLayer.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2025/11/14.
//

import SwiftUI

struct MapHighlightLayer: View {

    @Environment(Mapper.self) var mapper

    @State var isVisible: Bool = true

    @AppStorage(wrappedValue: true, "Customization.UseDarkModeMaps") var useDarkModeMaps: Bool

    var body: some View {
        Canvas { context, _ in
            if let highlightData = mapper.highlightData, isVisible {
                context.fill(
                    Path(highlightData.sourceRect),
                    with: !useDarkModeMaps ? .color(.black.opacity(0.9)) :
                            .color(.primary.opacity(0.9))
                )
            }
        }
        .frame(width: mapper.canvasSize.width, height: mapper.canvasSize.height)
        .allowsHitTesting(false)
        .onChange(of: mapper.highlightData) { _, newValue in
            if let newValue, newValue.shouldBlink {
                Task {
                    await startBlinking()
                }
            } else {
                isVisible = true
            }
        }
    }

    func startBlinking() async {
        isVisible = true
        for _ in 0...6 {
            await blink()
        }
        mapper.highlightData = nil
        mapper.highlightTarget = nil
    }

    func blink() async {
        withAnimation(.easeInOut(duration: 0.2)) {
            isVisible.toggle()
        }
        try? await Task.sleep(for: .seconds(0.2))
    }
}
