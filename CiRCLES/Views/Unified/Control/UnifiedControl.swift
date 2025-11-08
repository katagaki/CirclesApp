//
//  UnifiedControl.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2025/07/21.
//

import SwiftData
import SwiftUI

struct UnifiedControl: View {
    @Environment(UserSelections.self) var selections

    var body: some View {
        Group {
            if #available(iOS 26.0, *) {
                HStack {
                    DatePicker()
                        .padding([.leading], 12.0)
                    Spacer()
                    HallPicker()
                        .background(accentColorForMap(selections.map))
                        .clipShape(.capsule)
                }
            } else {
                HStack {
                    DatePicker()
                        .padding([.leading], 12.0)
                    Spacer()
                    HallPicker()
                        .background(accentColorForMap(selections.map))
                        .clipShape(.capsule)
                }
                .padding(.horizontal, 1.5)
                .background(Material.bar)
                .clipShape(.capsule)
                .overlay {
                    Capsule()
                        .stroke(.primary.opacity(0.2), lineWidth: 1 / 3)
                }
            }
        }
        .padding(6.0)
        .id(selections.fullMapId)
    }

    func accentColorForMap(_ map: ComiketMap?) -> Color? {
        if let map {
            if map.name.starts(with: "東") {
                return Color.red
            } else if map.name.starts(with: "西") {
                return Color.blue
            } else if map.name.starts(with: "南") {
                return Color.green
            } else if map.name.starts(with: "会議") || map.name.starts(with: "会") {
                return Color.gray
            }
        }
        return Color.accentColor
    }
}
