//
//  InteractiveMapButton.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2024/08/15.
//

import SwiftUI

struct InteractiveMapButton: View {

    @Environment(DatabaseManager.self) var database

    @Binding var selectedEventDate: ComiketDate?

    @State var layout: ComiketLayout

    @State var isCircleDetailPopoverPresented: Bool = false
    @State var circlesInSpace: [ComiketCircle] = []

    var body: some View {
        Button {
            if let selectedEventDate {
                circlesInSpace = database.circles(in: layout, on: selectedEventDate.id)
            } else {
                circlesInSpace = database.circles(in: layout)
            }
            isCircleDetailPopoverPresented.toggle()
        } label: {
            Rectangle()
                .foregroundStyle(isCircleDetailPopoverPresented ? .accent.opacity(0.3) : .clear)
        }
        .popover(isPresented: $isCircleDetailPopoverPresented) {
            InteractiveMapDetailPopover(isPresented: $isCircleDetailPopoverPresented, circles: $circlesInSpace)
        }
    }
}
