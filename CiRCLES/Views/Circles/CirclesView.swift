//
//  CirclesView.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2024/07/21.
//

import SwiftUI

struct CirclesView: View {
    @EnvironmentObject var navigationManager: NavigationManager
    @Environment(AuthManager.self) var authManager
    @Environment(EventManager.self) var eventManager
    @Environment(DatabaseManager.self) var database

    @State var searchTerm: String = ""

    let phoneColumnConfiguration = [GridItem(.adaptive(minimum: 60.0), spacing: 2.0)]
#if targetEnvironment(macCatalyst)
    let padOrMacColumnConfiguration = [GridItem(.adaptive(minimum: 60.0), spacing: 2.0)]
#else
    let padOrMacColumnConfiguration = [GridItem(.adaptive(minimum: 100.0), spacing: 2.0)]
#endif

    var body: some View {
        NavigationStack(path: $navigationManager[.circles]) {
            ScrollView {
                LazyVGrid(columns: UIDevice.current.userInterfaceIdiom == .phone ?
                          phoneColumnConfiguration : padOrMacColumnConfiguration,
                          spacing: 2.0) {
                    ForEach(database.eventCircles.sorted(by: {$0.id < $1.id})) { circle in
                        NavigationLink(value: ViewPath.circlesDetail(circle: circle)) {
                            if let image = database.circleImage(for: circle.id) {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFit()
                            } else {
                                Text(circle.circleName)
                            }
                        }
                    }
                }
            }
            .searchable(text: $searchTerm,
                        placement: .navigationBarDrawer(displayMode: .always))
            .navigationDestination(for: ViewPath.self) { viewPath in
                switch viewPath {
                case .circlesDetail(let circle): CircleDetailView(circle: circle)
                default: Color.clear
                }
            }
        }
    }
}
