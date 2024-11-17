//
//  MapToolbar.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2024/09/09.
//

import Komponents
import SwiftData
import SwiftUI

struct MapToolbar: View {

    @Query(sort: [SortDescriptor(\ComiketDate.id, order: .forward)])
    var dates: [ComiketDate]

    @Query(sort: [SortDescriptor(\ComiketMap.id, order: .forward)])
    var maps: [ComiketMap]

    @Binding var selectedDate: ComiketDate?
    @Binding var selectedMap: ComiketMap?

    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 12.0) {
                ForEach(dates, id: \.id) { date in
                    Group {
                        if UIDevice.current.userInterfaceIdiom != .pad {
                            VStack(alignment: .leading, spacing: 12.0) {
                                HStack {
                                    Text("Shared.\(date.id)th.Day")
                                        .bold()
                                    Spacer()
                                    Text(date.date, style: .date)
                                        .foregroundStyle(.secondary)
                                }
                                Divider()
                                HStack(spacing: 8.0) {
                                    ForEach(maps, id: \.id) { map in
                                        BarAccessoryButton(LocalizedStringKey(stringLiteral: map.name),
                                                           accentColor: accentColorForMap(map),
                                                           isTextLight: true) {
                                            withAnimation(.snappy.speed(2.0)) {
                                                selectedDate = date
                                                selectedMap = map
                                            }
                                        }
                                        .disabled(selectedDate == date && selectedMap == map)
                                    }
                                }
                            }
                        } else {
                            HStack(alignment: .center, spacing: 12.0) {
                                VStack(alignment: .leading) {
                                    Text("Shared.\(date.id)th.Day")
                                        .bold()
                                    Text(date.date, style: .date)
                                        .foregroundStyle(.secondary)
                                }
                                HStack(spacing: 8.0) {
                                    ForEach(maps, id: \.id) { map in
                                        BarAccessoryButton(LocalizedStringKey(stringLiteral: map.name),
                                                           accentColor: accentColorForMap(map),
                                                           isTextLight: true) {
                                            withAnimation(.snappy.speed(2.0)) {
                                                selectedDate = date
                                                selectedMap = map
                                            }
                                        }
                                        .disabled(selectedDate == date && selectedMap == map)
                                    }
                                }
                            }
                        }
                    }
                    .padding(12.0)
                    .background {
                        if date.id == selectedDate?.id {
                            RoundedRectangle(cornerRadius: 12.0)
                                .foregroundStyle(Color.primary.opacity(0.1))
                        } else {
                            RoundedRectangle(cornerRadius: 12.0)
                                .stroke(Color.primary.opacity(0.1))
                        }
                    }
                }
            }
            .padding([.leading, .trailing], 12.0)
            .padding([.top, .bottom], 12.0)
        }
        .scrollIndicators(.hidden)
    }

    func accentColorForMap(_ map: ComiketMap) -> Color? {
        if map.name.starts(with: "東") {
            return Color.red
        } else if map.name.starts(with: "西") {
            return Color.blue
        } else if map.name.starts(with: "南") {
            return Color.green
        } else if map.name.starts(with: "会議") || map.name.starts(with: "会") {
            return Color.gray
        } else {
            return nil
        }
    }
}
