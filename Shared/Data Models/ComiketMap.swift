//
//  ComiketMap.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2024/07/15.
//

import SwiftData

@Model
final class ComiketMap {
    var comiketNumber: Int
    var name: String
    var filename: String?
    var width: Int?
    var height: Int?

    init(comiketNumber: Int, name: String) {
        self.comiketNumber = comiketNumber
        self.name = name
    }
}
