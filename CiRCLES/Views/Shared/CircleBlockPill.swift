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
        switch size {
        case .large:
            Text(text)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundStyle(Color(uiColor: UIColor.label))
                .padding([.top, .bottom], 2.0)
                .padding([.leading, .trailing], 10.0)
                .background(.background.opacity(0.8))
                .clipShape(.capsule(style: .continuous))
                .overlay {
                    Capsule()
                        .stroke(lineWidth: 1)
                        .foregroundColor(.secondary)
                }
        case .small:
            Text(text)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(Color(uiColor: UIColor.label))
                .padding([.top, .bottom], 2.0)
                .padding([.leading, .trailing], 6.0)
                .background(.background.opacity(0.8))
                .clipShape(.capsule(style: .continuous))
                .overlay {
                    Capsule()
                        .stroke(lineWidth: 1)
                        .foregroundColor(.secondary)
                }
        }
    }
}
