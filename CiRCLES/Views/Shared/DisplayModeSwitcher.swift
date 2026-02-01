//
//  DisplayModeSwitcher.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2025/11/02.
//

import SwiftUI

struct DisplayModeSwitcher: View {

    @Binding var mode: CircleDisplayMode

    var body: some View {
        Button {
            withAnimation(.smooth.speed(2.0)) {
                switch mode {
                case .grid: mode = .list
                case .list: mode = .grid
                }
            }
        } label: {
            switch mode {
            case .grid:
                Label("Shared.DisplayMode.List", systemImage: "rectangle.grid.1x2")
            case .list:
                Label("Shared.DisplayMode.Grid", systemImage: "rectangle.grid.3x2")
            }
        }
    }
}
