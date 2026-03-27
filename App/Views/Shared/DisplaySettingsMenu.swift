//
//  DisplaySettingsMenu.swift
//  CiRCLES
//
//  Created by Claude on 2026/03/24.
//

import SwiftUI

struct DisplaySettingsMenu: View {

    @Binding var displayMode: CircleDisplayMode
    @Binding var listDisplayMode: ListDisplayMode
    @Binding var gridDisplayMode: GridDisplayMode

    var body: some View {
        Menu {
            Picker("DisplaySettings.ViewMode", selection: $displayMode.animation(.smooth.speed(2.0))) {
                Label("DisplaySettings.ViewMode.Grid", systemImage: "rectangle.grid.3x2")
                    .tag(CircleDisplayMode.grid)
                Label("DisplaySettings.ViewMode.List", systemImage: "rectangle.grid.1x2")
                    .tag(CircleDisplayMode.list)
            }
            if displayMode == .grid {
                Picker("DisplaySettings.GridSize", selection: $gridDisplayMode.animation(.smooth.speed(2.0))) {
                    Label("DisplaySettings.GridSize.Big", systemImage: "square.grid.2x2")
                        .tag(GridDisplayMode.big)
                    Label("DisplaySettings.GridSize.Medium", systemImage: "square.grid.3x3")
                        .tag(GridDisplayMode.medium)
                    Label("DisplaySettings.GridSize.Small", systemImage: "square.grid.4x3.fill")
                        .tag(GridDisplayMode.small)
                }
            }
            if displayMode == .list {
                Picker("DisplaySettings.ListSize", selection: $listDisplayMode.animation(.smooth.speed(2.0))) {
                    Label("DisplaySettings.ListSize.Regular", systemImage: "rectangle.expand.vertical")
                        .tag(ListDisplayMode.regular)
                    Label("DisplaySettings.ListSize.Compact", systemImage: "rectangle.compress.vertical")
                        .tag(ListDisplayMode.compact)
                }
            }
        } label: {
            Label("DisplaySettings", systemImage: "gearshape")
        }
        .menuActionDismissBehavior(.disabled)
    }
}
