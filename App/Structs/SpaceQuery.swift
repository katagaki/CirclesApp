//
//  SpaceQuery.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2026/08/25.
//

import Foundation

struct SpaceQuery {
    let blockName: String
    let spaceNumber: Int
    let spaceNumberSuffix: Int?

    init?(_ term: String) {
        let pattern = /^([^\p{Nd}\s\-ー]{1,3})\s*(\d{1,3})\s*([a-c])?$/.ignoresCase()
        guard let match = Self.halfwidthASCII(term).wholeMatch(of: pattern),
              let spaceNumber = Int(match.2) else { return nil }
        self.blockName = String(match.1)
        self.spaceNumber = spaceNumber
        switch match.3?.lowercased() {
        case "a": self.spaceNumberSuffix = 0
        case "b": self.spaceNumberSuffix = 1
        case "c": self.spaceNumberSuffix = 2
        default: self.spaceNumberSuffix = nil
        }
    }

    private static func halfwidthASCII(_ term: String) -> String {
        String(String.UnicodeScalarView(term.unicodeScalars.map {
            (0xFF01...0xFF5E).contains(Int($0.value))
                ? Unicode.Scalar(UInt32(Int($0.value) - 0xFEE0)) ?? $0
                : $0
        }))
    }

    func blockNameCandidates() -> [String] {
        (0..<blockName.count).map { String(blockName.dropFirst($0)) }
    }
}
