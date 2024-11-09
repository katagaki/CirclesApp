//
//  CircleListRegularRow.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2024/09/08.
//

import SwiftUI

struct CircleListRegularRow: View {
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
                circle, in: namespace, shouldFetchWebCut: showWebCut,
                showSpaceName: .constant(false), showDay: .constant(false)
            )
            .matchedGeometryEffect(id: "\(circle.id).Cut", in: namespace)
            .automaticMatchedTransitionSource(id: circle.id, in: namespace)
            .frame(width: 70.0, height: 100.0, alignment: .center)
            VStack(alignment: .leading, spacing: 5.0) {
                Text(circle.circleName)
                if circle.penName.trimmingCharacters(in: .whitespacesAndNewlines) != "" {
                    Text(circle.penName)
                        .foregroundStyle(.secondary)
                }
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
        }
    }
}
