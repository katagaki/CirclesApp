//
//  GridModeSwitcher.swift
//  CiRCLES
//
//  Created by Antigravity on 2026/02/01.
//

import SwiftUI

struct GridModeSwitcher: View {

    @Binding var mode: GridDisplayMode

    var body: some View {
        Menu {
            Picker("Circles.GridSize", selection: $mode.animation(.smooth.speed(2.0))) {
                Label("Shared.DisplayMode.Grid.Big", systemImage: "square.grid.2x2")
                    .tag(GridDisplayMode.big)
                Label("Shared.DisplayMode.Grid.Medium", systemImage: "square.grid.3x3")
                    .tag(GridDisplayMode.medium)
                Label("Shared.DisplayMode.Grid.Small", systemImage: "square.grid.4x3.fill")
                    .tag(GridDisplayMode.small)
            }
        } label: {
            switch mode {
            case .big:
                Label("Shared.DisplayMode.Grid.Big", systemImage: "square.grid.2x2")
            case .medium:
                Label("Shared.DisplayMode.Grid.Medium", systemImage: "square.grid.3x3")
            case .small:
                Label("Shared.DisplayMode.Grid.Small", systemImage: "square.grid.4x3.fill")
            }
        }
    }
}
