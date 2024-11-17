//
//  CirclePreview.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2024/09/02.
//

import SwiftUI

struct CirclePreview: View {

    var database: Database

    var circle: ComiketCircle

    @AppStorage(wrappedValue: false, "Customization.ShowSpaceName") var showSpaceName: Bool
    @AppStorage(wrappedValue: false, "Customization.ShowDay") var showDay: Bool
    @AppStorage(wrappedValue: false, "Customization.ShowWebCut") var showWebCut: Bool

    @Namespace var namespace

    var body: some View {
        VStack(alignment: .center, spacing: 6.0) {
            CircleCutImage(
                circle,
                in: namespace,
                shouldFetchWebCut: showWebCut,
                showCatalogCut: true,
                showSpaceName: .constant(showSpaceName),
                showDay: .constant(showDay)
            )
            Text(circle.circleName)
        }
        .padding()
    }
}
