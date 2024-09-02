//
//  CirclePreview.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2024/09/02.
//

import SwiftUI

struct CirclePreview: View {

    var database: DatabaseManager

    var circle: ComiketCircle

    @State var circleImage: UIImage?

    var body: some View {
        VStack(alignment: .center, spacing: 6.0) {
            if let circleImage {
                Image(uiImage: circleImage)
            }
            Text(circle.circleName)
        }
        .padding()
        .onAppear {
            if let circleImage = database.circleImage(for: circle.id) {
                self.circleImage = circleImage
            }
        }
    }
}
