//
//  CircleDetailView.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2024/07/21.
//

import SwiftUI

struct CircleDetailView: View {
    @Environment(DatabaseManager.self) var database

    var circle: ComiketCircle
    @State var circleImage: UIImage?

    var body: some View {
        List {
            Text(circle.supplementaryDescription)
            Text(circle.memo)
        }
        .navigationTitle(circle.circleName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(circle.circleName)
                    .font(.title)
                    .bold()
            }
        }
        .safeAreaInset(edge: .top) {
            ToolbarAccessory(placement: .top) {
                VStack {
                    if let circleImage {
                        Image(uiImage: circleImage)
                    }
                    Text(circle.penName)
                        .bold()
                    Text(circle.bookName)
                }
            }
        }
        .task {
            if let circleImage = database.circleImage(for: circle.id) {
                self.circleImage = circleImage
            }
        }
    }
}
