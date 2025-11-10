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
    let showContextMenu: Bool

    @State var isShowingTranslationPopover: Bool = false

    init(title: String, contents: String, canTranslate: Bool, showContextMenu: Bool = true) {
        self.title = title
        self.contents = contents
        self.canTranslate = canTranslate
        self.showContextMenu = showContextMenu
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4.0) {
            Group {
                Text(LocalizedStringKey(title))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)

                if showContextMenu {
                    if canTranslate {
#if !targetEnvironment(macCatalyst) && !os(visionOS)
                        Text(contents)
                            .font(.subheadline)
                            .textSelection(.enabled)
                            .contextMenu {
                                Button("Shared.Copy", systemImage: "doc.on.doc") {
                                    UIPasteboard.general.string = contents
                                }
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
                            .contextMenu {
                                Button("Shared.Copy", systemImage: "doc.on.doc") {
                                    UIPasteboard.general.string = contents
                                }
                            }
#endif
                    } else {
                        Text(contents)
                            .font(.subheadline)
                            .textSelection(.enabled)
                            .contextMenu {
                                Button("Shared.Copy", systemImage: "doc.on.doc") {
                                    UIPasteboard.general.string = contents
                                }
                            }
                    }
                } else {
                    Text(contents)
                        .font(.subheadline)
                        .textSelection(.enabled)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
