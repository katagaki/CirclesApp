//
//  Size.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2024/07/21.
//

import CoreGraphics

struct Size: Codable {
    var width: Int
    var height: Int

    func cgSize() -> CGSize {
        return CGSize(width: width, height: height)
    }
}
