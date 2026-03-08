//
//  CircleDetailSection.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2026/03/01.
//

import SwiftUI

enum CircleDetailSection: Int, CaseIterable, Codable, Identifiable {
    case bookName = 0
    case genre = 1
    case tags = 2
    case memo = 3
    case attachments = 4

    var id: Int { rawValue }

    var localizedName: LocalizedStringKey {
        switch self {
        case .bookName: "CircleDetailSection.BookName"
        case .genre: "CircleDetailSection.Genre"
        case .tags: "CircleDetailSection.Tags"
        case .memo: "CircleDetailSection.Memo"
        case .attachments: "CircleDetailSection.Attachments"
        }
    }

    static let defaultOrder: [CircleDetailSection] = CircleDetailSection.allCases
}
