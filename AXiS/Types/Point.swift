//
//  Point.swift
//  AXiS
//
//  Created by シン・ジャスティン on 2024/07/21.
//

import CoreGraphics

// swiftlint:disable identifier_name
public struct Point: Codable {
    public var x: Int
    public var y: Int

    public init(x: Int, y: Int) {
        self.x = x
        self.y = y
    }

    public func cgPoint() -> CGPoint {
        return CGPoint(x: x, y: y)
    }
}
// swiftlint:enable identifier_name
