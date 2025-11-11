//
//  Display.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2025/11/11.
//

import Foundation

func zoomFactor(_ zoomDivisor: Int) -> CGFloat {
    return 1 + CGFloat(zoomDivisor) * 0.3
}

func zoomFactorDouble(_ zoomDivisor: Int) -> Double {
    return 1 + Double(zoomDivisor) * 0.3
}
