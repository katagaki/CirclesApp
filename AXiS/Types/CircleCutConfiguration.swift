//
//  CircleCutConfiguration.swift
//  AXiS
//
//  Created by シン・ジャスティン on 2024/07/21.
//

public struct CircleCutConfiguration: Codable {
    public var size: Size
    public var origin: Point
    public var offset: Point

    public init(size: Size, origin: Point, offset: Point) {
        self.size = size
        self.origin = origin
        self.offset = offset
    }
}
