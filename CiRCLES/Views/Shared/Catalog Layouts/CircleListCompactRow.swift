//
//  CircleListCompactRow.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2024/09/08.
//

import SwiftUI

struct CircleListCompactRow: View {
    @Environment(Database.self) var database
    @Environment(Favorites.self) var favorites

    var circle: ComiketCircle
    var namespace: Namespace.ID

    @AppStorage(wrappedValue: false, "Customization.ShowSpaceName") var showSpaceName: Bool
    @AppStorage(wrappedValue: false, "Customization.ShowDay") var showDay: Bool
    @AppStorage(wrappedValue: false, "Customization.ShowWebCut") var showWebCut: Bool

    var body: some View {
        HStack(spacing: 10.0) {
            CircleCutImage(
                circle, in: namespace, cutType: .web,
                showSpaceName: .constant(false), showDay: .constant(false)
            )
            .matchedGeometryEffect(id: "\(circle.id).Cut", in: namespace)
            .matchedTransitionSource(id: circle.id, in: namespace)
            .frame(width: 28.0, height: 40.0, alignment: .center)
            Text(circle.circleName)
                .strikethrough(circle: circle)
            Spacer()
            if showSpaceName || showDay {
                HStack(alignment: .center) {
                    if showDay {
                        CircleBlockPill("Shared.\(circle.day)th.Day")
                            .matchedGeometryEffect(id: "\(circle.id).Day", in: namespace)
                    }
                    if showSpaceName, let spaceName = circle.spaceName() {
                        CircleBlockPill(LocalizedStringKey(spaceName))
                            .matchedGeometryEffect(id: "\(circle.id).Space", in: namespace)
                    }
                }
            }
        }
        .matchedTransitionSource(id: circle.id, in: namespace)
    }
}
