//
//  InfoStackSection.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2025/11/10.
//

import Foundation
import SwiftUI

struct InfoStackSection: View {
    let title: String
    let contents: String
    let canTranslate: Bool
    
    @State var isShowingTranslationPopover: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 4.0) {
            HStack(alignment: .center, spacing: 4.0) {
                Text(LocalizedStringKey(title))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                if canTranslate {
                    TranslateButton(translating: contents)
                }
            }  
            
            if canTranslate {
                #if !targetEnvironment(macCatalyst) && !os(visionOS)
                Text(contents)
                    .font(.subheadline)
                    .textSelection(.enabled)
                    .contextMenu {
                        Button("Shared.Translate", systemImage: "character.bubble") {
                            isShowingTranslationPopover = true
                        }
                    }
                    .translationPresentation(
                        isPresented: $isShowingTranslationPopover,
                        text: contents
                    )
                #else
                Text(contents)
                    .font(.subheadline)
                    .textSelection(.enabled)
                #endif
            } else {
                Text(contents)
                    .font(.subheadline)
                    .textSelection(.enabled)
            }
        }
    }
}