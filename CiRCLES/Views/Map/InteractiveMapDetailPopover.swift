//
//  InteractiveMapDetailPopover.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2024/08/15.
//

import SwiftUI

struct InteractiveMapDetailPopover: View {
    @Binding var circles: [ComiketCircle]

    var body: some View {
        List(circles, id: \.id) { circle in
            Text(circle.circleName)
        }
        .frame(minWidth: 300.0, maxWidth: .infinity, minHeight: 300.0, maxHeight: .infinity)
        .presentationCompactAdaptation(.popover)
    }
}
