//
//  CircleGrid.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2024/08/30.
//

import SwiftUI

struct CircleGrid: View {

    @Environment(DatabaseManager.self) var database

    let gridSpacing: CGFloat = 1.0

    var circles: [ComiketCircle]
    var favorites: [Int: UserFavorites.Response.FavoriteItem]?
    var namespace: Namespace.ID
    var onSelect: ((ComiketCircle) -> Void)

    @State var isHallAndBlockMappingsReady: Bool = false
    @State var hallAndBlockMappings: [Int: String] = [:]

    @AppStorage(wrappedValue: false, "Customization.ShowHallAndBlock") var showHallAndBlock: Bool
    @AppStorage(wrappedValue: false, "Customization.ShowDay") var showDay: Bool

    var body: some View {

        let phoneColumnConfiguration = [GridItem(.adaptive(minimum: 70.0), spacing: gridSpacing)]
        #if targetEnvironment(macCatalyst)
        let padOrMacColumnConfiguration = [GridItem(.adaptive(minimum: 80.0), spacing: gridSpacing)]
        #else
        let padOrMacColumnConfiguration = [GridItem(.adaptive(minimum: 100.0), spacing: gridSpacing)]
        #endif

        ScrollView {
            LazyVGrid(columns: UIDevice.current.userInterfaceIdiom == .phone ?
                      phoneColumnConfiguration : padOrMacColumnConfiguration,
                      spacing: gridSpacing) {
                ForEach(circles) { circle in
                    Button {
                        onSelect(circle)
                    } label: {
                        Group {
                            if let image = database.circleImage(for: circle.id) {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFit()
                            } else {
                                ZStack(alignment: .center) {
                                    ProgressView()
                                    Color.clear
                                }
                                .aspectRatio(0.7, contentMode: .fit)
                            }
                        }
                        .overlay {
                            GeometryReader { proxy in
                                ZStack(alignment: .topLeading) {
                                    if let favorites, let extendedInformation = circle.extendedInformation,
                                       let favorite = favorites[extendedInformation.webCatalogID] {
                                        favorite.favorite.color.swiftUIColor()
                                            .frame(width: 0.23 * proxy.size.width,
                                                   height: 0.23 * proxy.size.width)
                                            .offset(x: 0.03 * proxy.size.width,
                                                    y: 0.03 * proxy.size.width)
                                    }
                                    Color.clear
                                }
                            }
                        }
                        .overlay {
                            if showHallAndBlock || showDay {
                                ZStack(alignment: .bottomTrailing) {
                                    VStack(alignment: .trailing, spacing: 2.0) {
                                        Group {
                                            if showDay {
                                                Text("Shared.\(circle.day)th.Day")
                                            }
                                            if showHallAndBlock,
                                                let hallAndBlockName = hallAndBlockMappings[circle.id] {
                                                Text(hallAndBlockName)
                                            }
                                        }
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundStyle(Color(uiColor: UIColor.label))
                                        .padding([.top, .bottom], 2.0)
                                        .padding([.leading, .trailing], 6.0)
                                        .background(.background.opacity(0.8))
                                        .clipShape(.capsule)
                                        .overlay {
                                            Capsule()
                                                .stroke(lineWidth: 1)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    .padding(2.0)
                                    Color.clear
                                }
                            }
                        }
                    }
                    .automaticMatchedTransitionSource(id: circle.id, in: namespace)
                }
            }
        }
        .onAppear {
            if !isHallAndBlockMappingsReady {
                Task.detached {
                    await reloadMappings()
                }
                isHallAndBlockMappingsReady = true
            }
        }
        .onChange(of: circles) { _, _ in
            Task.detached {
                await reloadMappings()
            }
        }
    }

    func reloadMappings() async {
        debugPrint("Getting display text mappings for circle grid")
        let actor = DataFetcher(modelContainer: sharedModelContainer)

        var hallAndBlockMappings: [Int: String] = [:]
        for circle in circles {
            let circleID = circle.id
            let blockName = await actor.blockName(circle.blockID)
            if let blockName {
                hallAndBlockMappings[circleID] = "\(blockName)\(circle.spaceNumberCombined())"
            }
        }

        await MainActor.run {
            self.hallAndBlockMappings = hallAndBlockMappings
        }
    }
}
