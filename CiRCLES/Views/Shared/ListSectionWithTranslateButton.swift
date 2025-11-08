//
//  ListSectionWithTranslateButton.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2024/11/30.
//

import Foundation
import SwiftUI

struct ListSectionWithTranslateButton: View {
    var title: String
    var text: String
    var body: some View {
        Section {
            Text(text)
                .textSelection(.enabled)
        } header: {
            HStack {
                Text(LocalizedStringKey(title))
                Spacer()
                if text.trimmingCharacters(in: .whitespacesAndNewlines).count > 0 {
                    TranslateButton(translating: text)
                }
            }
        }
    }
}
