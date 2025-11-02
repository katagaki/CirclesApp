//
//  DisplayModeSwitcher.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2025/11/02.
//

import SwiftUI

struct DisplayModeSwitcher: View {

    @Binding var modeState: CircleDisplayMode

    @AppStorage(wrappedValue: CircleDisplayMode.grid, "Circles.DisplayMode") var mode: CircleDisplayMode

    init(_ modeState: Binding<CircleDisplayMode>) {
        self._modeState = modeState
    }

    var body: some View {
        Button {
            withAnimation(.smooth.speed(2.0)) {
                switch modeState {
                case .grid: modeState = .list
                case .list: modeState = .grid
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
        .onAppear {
            self.modeState = mode
        }
        .onChange(of: modeState) {
            mode = modeState
        }
    }
}
