//
//  MapHallMenu.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2025/06/07.
//

import SwiftData
import SwiftUI

struct MapHallMenu: View {

    @Query(sort: [SortDescriptor(\ComiketDate.id, order: .forward)])
    var dates: [ComiketDate]

    @Query(sort: [SortDescriptor(\ComiketMap.id, order: .forward)])
    var maps: [ComiketMap]

    @Binding var selectedDate: ComiketDate?
    @Binding var selectedMap: ComiketMap?

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            SquareButtonStack {
                Menu {
                    ForEach(dates, id: \.id) { date in
                        Section("Shared.\(date.id)th.Day") {
                            ForEach(maps, id: \.id) { map in
                                Button {
                                    withAnimation(.smooth.speed(2.0)) {
                                        selectedDate = date
                                        selectedMap = map
                                    }
                                } label: {
                                    if selectedDate == date && selectedMap == map {
                                        Label(LocalizedStringKey(stringLiteral: map.name),
                                              systemImage: "checkmark")
                                    } else {
                                        Text(LocalizedStringKey(stringLiteral: map.name))
                                    }
                                }
                                .disabled(selectedDate == date && selectedMap == map)
                            }
                        }
                    }
                } label: {
                    SquareButton {
                        // Intentionally left blank
                    } label: {
                        Image(systemName: "building")
                            .font(.title2)
                    }
                }
            }
            .offset(x: -12.0, y: -12.0)
            Color.clear
        }
    }
}
