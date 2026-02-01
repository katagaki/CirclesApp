//
//  HallPicker.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2025/09/21.
//

import SwiftData
import SwiftUI

struct HallPicker: View {
    @Environment(UserSelections.self) var selections
    @Environment(Database.self) var database
    @State var maps: [ComiketMap] = []

    var body: some View {
        Menu {
            ForEach(maps, id: \.id) { map in
                Button(map.name,
                       systemImage: selections.map == map ? "checkmark" : "") {
                    selections.map = map
                }
            }
        } label: {
            HStack(spacing: 10.0) {
                Image(systemName: "building")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 20.0)
                if let selectedMap = selections.map {
                    Text(selectedMap.name)
                } else {
                    Text("Shared.Placeholder.NoBlock")
                }
            }
            .padding(.vertical, verticalPadding())
            .padding(.horizontal, horizontalPadding())
            .foregroundStyle(.white)

        }
        .task {
            database.connect()
            maps = database.allMaps()
        }
    }

    func horizontalPadding() -> CGFloat {
        if #available(iOS 26.0, *) {
            16.0
        } else {
            12.0
        }
    }

    func verticalPadding() -> CGFloat {
        if #available(iOS 26.0, *) {
            12.0
        } else {
            4.0
        }
    }
}
