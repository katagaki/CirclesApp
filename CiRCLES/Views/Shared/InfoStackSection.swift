//
//  InfoStackSection.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2025/11/10.
//

import Foundation
import SwiftUI

struct InfoStackSection: View {
    let title: LocalizedStringKey
    let contents: String
    let canTranslate: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 4.0) {
            HStack(alignment: .center, spacing: 4.0) {
                Text(String(localized: title))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                if canTranslate {
                    TranslateButton(translating: contents)
                }
            }  
            Text(contents)
                .font(.subheadline)
        }
    }
}