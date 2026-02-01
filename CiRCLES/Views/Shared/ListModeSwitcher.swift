//
//  ListModeSwitcher.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2025/11/02.
//

import SwiftUI

struct ListModeSwitcher: View {

    @Binding var mode: ListDisplayMode

    var body: some View {
        Button {
            withAnimation(.smooth.speed(2.0)) {
                switch mode {
                case .regular: mode = .compact
                case .compact: mode = .regular
                }
            }
        } label: {
            switch mode {
            case .regular:
                Label("Shared.DisplayMode.List.Compact", systemImage: "rectangle.compress.vertical")
            case .compact:
                Label("Shared.DisplayMode.List.Regular", systemImage: "rectangle.expand.vertical")
            }
        }
    }
}
