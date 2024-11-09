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

    @AppStorage(wrappedValue: false, "Customization.ShowWebCut") var showWebCut: Bool

    @Namespace var namespace

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
                                CircleCutImage(
                                    circle, in: namespace, shouldFetchWebCut: showWebCut,
                                    showSpaceName: .constant(false), showDay: .constant(false)
                                )
                                    .frame(width: 70.0, height: 100.0, alignment: .center)
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
