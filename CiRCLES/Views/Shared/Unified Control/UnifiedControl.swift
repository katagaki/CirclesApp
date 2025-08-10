//
//  UnifiedControl.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2025/07/21.
//

import Komponents
import SwiftData
import SwiftUI

struct UnifiedControl: View {
    @Environment(UserSelections.self) var selections

    @Query(sort: [SortDescriptor(\ComiketDate.id, order: .forward)])
    var dates: [ComiketDate]

    @Query(sort: [SortDescriptor(\ComiketMap.id, order: .forward)])
    var maps: [ComiketMap]

    var body: some View {
        HStack(spacing: 12.0) {
            Menu {
                ForEach(dates, id: \.id) { date in
                    Button("Shared.\(date.id)th.Day",
                           systemImage: selections.date == date ? "checkmark" : "") {
                        selections.date = date
                    }
                }
            } label: {
                HStack(spacing: 10.0) {
                    if let selectedDateDate = selections.date?.date {
                        let calendarDate = Calendar.current.dateComponents(
                            [.day, .year, .month],
                            from: selectedDateDate
                        )
                        Image(systemName: "\(calendarDate.day?.description ?? "ellipsis").calendar")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 20.0)
                    }
                    if let selectedDate = selections.date {
                        VStack(alignment: .leading) {
                            Text("Shared.\(selectedDate.id)th.Day")
                                .font(.caption)
                                .bold()
                            Text(selectedDate.date, style: .date)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    } else {
                        // TODO
                    }
                }
            }
            .padding([.leading], 12.0)
            Spacer()
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
                        // TODO
                    }
                }
                .padding([.top, .bottom], 12.0)
                .padding([.leading, .trailing], 16.0)
                .foregroundStyle(.white)
            }
            .background(accentColorForMap(selections.map))
            .clipShape(.capsule)
        }
        .padding(6.0)
        .id(selections.idMap)
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
        return nil
    }
}
