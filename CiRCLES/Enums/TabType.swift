//
//  TabType.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2024/07/15.
//

import Foundation
import Komponents

// swiftlint:disable identifier_name
enum TabType: Int, TabTypeProtocol {
    case map = 0
    case circles = 1
    case favorites = 2
    case my = 3
    case more = 4

    static let defaultTab: TabType = .map
}
// swiftlint:enable identifier_name
