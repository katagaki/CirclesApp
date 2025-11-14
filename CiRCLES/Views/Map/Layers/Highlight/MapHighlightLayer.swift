//
//  MapHighlightLayer.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2025/11/14.
//

import SwiftUI

struct MapHighlightLayer: View {
    
    @Binding var canvasSize: CGSize
    @Binding var highlightData: HighlightData?
    
    @State private var blinkCount: Int = 0
    @State private var isVisible: Bool = true
    
    @AppStorage(wrappedValue: true, "Customization.UseDarkModeMaps") var useDarkModeMaps: Bool
    
    var body: some View {
        Canvas { context, _ in
            if let highlightData, isVisible {
                context.fill(
                    Path(highlightData.sourceRect),
                    with: !useDarkModeMaps ? .color(.black.opacity(0.3)) :
                            .color(.primary.opacity(0.3))
                )
            }
        }
        .frame(width: canvasSize.width, height: canvasSize.height)
        .allowsHitTesting(false)
        .onChange(of: highlightData) { _, newValue in
            if let newValue, newValue.shouldBlink {
                startBlinking()
            } else {
                isVisible = true
                blinkCount = 0
            }
        }
    }
    
    func startBlinking() {
        blinkCount = 0
        isVisible = true
        blink()
    }
    
    func blink() {
        guard blinkCount < 6 else { // 3 full blinks (on-off-on-off-on-off)
            highlightData = nil
            return
        }
        
        withAnimation(.easeInOut(duration: 0.3)) {
            isVisible.toggle()
        }
        
        blinkCount += 1
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            blink()
        }
    }
}
