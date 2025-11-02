//
//  ListModeSwitcher.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2025/11/02.
//

import SwiftUI

struct ListModeSwitcher: View {

    @Binding var modeState: ListDisplayMode

    @AppStorage(wrappedValue: ListDisplayMode.regular, "Circles.ListSize") var mode: ListDisplayMode

    init(_ modeState: Binding<ListDisplayMode>) {
        self._modeState = modeState
    }

    var body: some View {
        Button {
            withAnimation(.smooth.speed(2.0)) {
                switch modeState {
                case .regular: modeState = .compact
                case .compact: modeState = .regular
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
        .onAppear {
            self.modeState = mode
        }
        .onChange(of: modeState) {
            mode = modeState
        }
    }
}
