//
//  ComiketCircleImage.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2025/06/01.
//

import Foundation
import SwiftData

@Model
final class ComiketCircleImage {
    var id: Int
    var cutImage: Data

    init(id: Int, cutImage: Data) {
        self.id = id
        self.cutImage = cutImage
    }
}
