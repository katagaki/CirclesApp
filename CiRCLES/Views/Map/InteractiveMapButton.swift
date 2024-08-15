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
                .foregroundStyle(Color(
                    red: .random(in: 0...1),
                    green: .random(in: 0...1),
                    blue: .random(in: 0...1),
                    opacity: 0.3
                ))
        }
        .popover(isPresented: $isCircleDetailPopoverPresented) {
            InteractiveMapDetailPopover(circles: $circlesInSpace)
        }
    }
}
