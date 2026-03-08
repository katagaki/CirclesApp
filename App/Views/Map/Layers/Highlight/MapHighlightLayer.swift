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
        let color: Color = !useDarkModeMaps ? .black.opacity(0.9) : .primary.opacity(0.9)
        ZStack(alignment: .topLeading) {
            if let highlightData = mapper.highlightData, isVisible {
                Rectangle()
                    .fill(color)
                    .frame(width: highlightData.sourceRect.width,
                           height: highlightData.sourceRect.height)
                    .position(x: highlightData.sourceRect.midX,
                              y: highlightData.sourceRect.midY)
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
        withAnimation(.easeInOut(duration: 0.16)) {
            isVisible.toggle()
        }
        try? await Task.sleep(for: .seconds(0.16))
    }
}
