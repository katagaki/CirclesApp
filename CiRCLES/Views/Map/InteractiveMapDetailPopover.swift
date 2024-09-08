//
//  InteractiveMapDetailPopover.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2024/08/15.
//

import SwiftUI

struct InteractiveMapDetailPopover: View {

    @EnvironmentObject var navigator: Navigator
    @Environment(Database.self) var database

    @Environment(\.modelContext) var modelContext

    @Binding var isPresented: Bool

    var webCatalogIDs: [Int]

    @State var circles: [ComiketCircle]?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8.0) {
                if let circles {
                    ForEach(circles, id: \.id) { circle in
                        Button {
                            isPresented = false
                            navigator.push(.circlesDetail(circle: circle), for: .map)
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
            .frame(minWidth: 210.0, minHeight: 208.0)
            .padding()
            .presentationCompactAdaptation(.popover)
            .onAppear {
                fetchCircles()
            }
        }
    }

    func fetchCircles() {
        Task.detached {
            let actor = DataFetcher(modelContainer: sharedModelContainer)
            let circleIdentifiers = await actor.circles(withWebCatalogIDs: webCatalogIDs)
            await MainActor.run {
                let circles = database.circles(circleIdentifiers)
                self.circles = circles
            }
        }
    }
}
