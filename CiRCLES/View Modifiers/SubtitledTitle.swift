//
//  SubtitledTitle.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2025/11/11.
//

import SwiftUI

struct SubtitledTitleModifier: ViewModifier {
    var title: String
    var subtitle: String

    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content
                .navigationTitle(title)
                .navigationSubtitle(subtitle)
                .toolbarTitleDisplayMode(.inlineLarge)
        } else {
            content
                .navigationTitle(title)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        VStack(spacing: 0.0) {
                            Text(title)
                                .bold()
                            if subtitle.trimmingCharacters(in: .whitespaces) != "" {
                                Text(subtitle)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
        }
    }
}

extension View {
    func subtitledTitle(_ title: String, subtitle: String) -> some View {
        self.modifier(SubtitledTitleModifier(
            title: title,
            subtitle: subtitle
        ))
    }
}
