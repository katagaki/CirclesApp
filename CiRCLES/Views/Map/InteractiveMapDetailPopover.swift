//
//  InteractiveMapDetailPopover.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2024/08/15.
//

import SwiftUI

struct InteractiveMapDetailPopover: View {

    @EnvironmentObject var navigationManager: NavigationManager
    @Environment(DatabaseManager.self) var database

    @Binding var isPresented: Bool

    var circles: [ComiketCircle]?

    var body: some View {
        VStack(alignment: .leading, spacing: 8.0) {
            if let circles {
                ForEach(circles, id: \.id) { circle in
                    Button {
                        isPresented = false
                        navigationManager.push(.circlesDetail(circle: circle), for: .map)
                    } label: {
                        HStack {
                            if let circleImage = database.circleImage(for: circle.id) {
                                Image(uiImage: circleImage)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 70.0, height: 100.0, alignment: .center)
                            }
                            Text(circle.circleName)
                            Spacer(minLength: 0.0)
                        }
                        .contentShape(.rect)
                    }
                    .buttonStyle(.plain)
                }
            } else {
                ProgressView()
                    .padding()
            }
        }
        .padding()
        .presentationCompactAdaptation(.popover)
    }
}
