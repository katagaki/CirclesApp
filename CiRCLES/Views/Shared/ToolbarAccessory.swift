//
//  ToolbarAccessory.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2024/07/21.
//

import SwiftUI

struct ToolbarAccessory<Content: View>: View {

    var placement: Placement
    @ViewBuilder let content: Content

    var body: some View {
        switch placement {
        case .top:
            content
                .frame(maxWidth: .infinity)
                .background(Material.bar)
                .overlay(alignment: .bottom) {
                    Rectangle()
                        .frame(height: 1/3)
                        .foregroundColor(.primary.opacity(0.2))
                        .ignoresSafeArea(edges: [.leading, .trailing])
                }
        case .bottom:
            content
                .frame(maxWidth: .infinity)
                .background(Material.bar)
                .overlay(alignment: .top) {
                    Rectangle()
                        .frame(height: 1/3)
                        .foregroundColor(.primary.opacity(0.2))
                        .ignoresSafeArea(edges: [.leading, .trailing])
                }
        }
    }

    enum Placement {
        case top
        case bottom
    }
}
