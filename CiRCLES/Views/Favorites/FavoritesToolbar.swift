//
//  FavoritesToolbar.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2024/11/16.
//

import Komponents
import SwiftData
import SwiftUI

struct FavoritesToolbar: View {

    @Query(sort: [SortDescriptor(\ComiketDate.id, order: .forward)])
    var dates: [ComiketDate]

    @Binding var selectedDate: ComiketDate?

    @Binding var isVisitModeOn: Bool

    @State var isInitialLoadCompleted: Bool = false

    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 12.0) {
                BarAccessoryButton(
                    "Shared.VisitMode",
                    icon: isVisitModeOn ? "checkmark.rectangle.stack.fill" : "checkmark.rectangle.stack",
                    isSecondary: !isVisitModeOn
                ) {
                    withAnimation(.snappy.speed(2.0)) {
                        isVisitModeOn.toggle()
                    }
                }
                .popoverTip(VisitModeTip())
                BarAccessoryMenu(
                    "Shared.Sort",
                    icon: "arrow.up.arrow.down"
                ) {
                    // TODO: Do sort
                }
                BarAccessoryMenu((selectedDate != nil ? "Shared.\(selectedDate!.id)th.Day" : "Shared.Day"),
                                 icon: "calendar") {
                    Button("Shared.All") {
                        selectedDate = nil
                    }
                    Picker(selection: $selectedDate.animation(.snappy.speed(2.0))) {
                        ForEach(dates) { date in
                            Text("Shared.\(date.id)th.Day")
                                .tag(date)
                        }
                    } label: {
                        Text("Shared.Day")
                    }
                }
            }
            .padding(.horizontal, 12.0)
            .padding(.vertical, 12.0)
        }
        .scrollIndicators(.hidden)
    }
}
