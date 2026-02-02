//
//  Point.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2024/07/21.
//

import CoreGraphics

// swiftlint:disable identifier_name
struct Point: Codable {
    var x: Int
    var y: Int

    func cgPoint() -> CGPoint {
        return CGPoint(x: x, y: y)
    }
}
// swiftlint:enable identifier_name
