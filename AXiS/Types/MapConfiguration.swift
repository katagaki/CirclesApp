//
//  MapConfiguration.swift
//  AXiS
//
//  Created by シン・ジャスティン on 2024/07/21.
//

public struct MapConfiguration: Codable {
    public var size: Size
    public var origin: Point

    public init(size: Size, origin: Point) {
        self.size = size
        self.origin = origin
    }
}
