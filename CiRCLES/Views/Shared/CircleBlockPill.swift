//
//  CircleBlockPill.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2024/09/01.
//

import SwiftUI

struct CircleBlockPill: View {

    var text: LocalizedStringKey
    var size: CircleBlockPillSize

    init(_ text: LocalizedStringKey, size: CircleBlockPillSize = .small) {
        self.text = text
        self.size = size
    }

    var body: some View {
        Group {
            switch size {
            case .large:
                Text(text)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color(uiColor: UIColor.label))
                    .padding(.vertical, 2.0)
                    .padding(.horizontal, 10.0)
            case .small:
                Text(text)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color(uiColor: UIColor.label))
                    .padding(.vertical, 2.0)
                    .padding(.horizontal, 6.0)
            }
        }
        .glassEffect()
        .clipShape(.capsule)
    }
}
