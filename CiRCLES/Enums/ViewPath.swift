//
//  ViewPath.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2024/07/15.
//

import Foundation
import Komponents

enum ViewPath: ViewPathProtocol {
    case circlesDetail(circle: ComiketCircle)
    case moreDBAdmin
    case moreAttributions

    nonisolated(unsafe) static let allCases: [ViewPath] = []

    typealias RawValue = String

    init?(rawValue: String) {
        return nil
    }

    var rawValue: String {
        switch self {
        case .circlesDetail(let circle):
            return "Circles.\(circle.id)"
        case .moreDBAdmin:
            return "More.DBAdmin"
        case .moreAttributions:
            return "More.Attributions"
        }
    }
}
