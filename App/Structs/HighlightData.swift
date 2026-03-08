//
//  HighlightData.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2025/11/14.
//

import Foundation

struct HighlightData: Equatable {
    var sourceRect: CGRect
    var shouldBlink: Bool = false

    static func == (lhs: HighlightData, rhs: HighlightData) -> Bool {
        lhs.sourceRect == rhs.sourceRect && lhs.shouldBlink == rhs.shouldBlink
    }
}
