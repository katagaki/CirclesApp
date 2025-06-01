//
//  ComiketCommonImage.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2025/06/01.
//

import Foundation
import SwiftData

@Model
final class ComiketCommonImage {
    var name: String
    var image: Data

    init(name: String, image: Data) {
        self.name = name
        self.image = image
    }
}
