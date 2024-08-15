//
//  InteractiveMapButton.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2024/08/15.
//

import SwiftUI

struct InteractiveMapButton: View {

    @Environment(DatabaseManager.self) var database

    @State var layout: ComiketLayout

    @State var isCircleDetailPopoverPresented: Bool = false
    @State var circlesInSpace: [ComiketCircle] = []

    var body: some View {
        Button {
            circlesInSpace = database.circles(in: layout)
            isCircleDetailPopoverPresented = true
        } label: {
            Rectangle()
                .foregroundStyle(.clear)
        }
        .popover(isPresented: $isCircleDetailPopoverPresented) {
            InteractiveMapDetailPopover(circles: $circlesInSpace)
        }
    }
}
