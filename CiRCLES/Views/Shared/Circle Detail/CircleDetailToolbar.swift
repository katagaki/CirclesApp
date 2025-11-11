//
//  CircleDetailToolbar.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2024/09/07.
//

import Komponents
import SwiftUI

struct CircleDetailToolbar: ToolbarContent {

    @Environment(Authenticator.self) var authenticator
    @Environment(Favorites.self) var favorites

    @Environment(\.openURL) var openURL

    let extendedInformation: ComiketCircleExtendedInformation
    let webCatalogInformation: WebCatalogCircle?

    @State var isAddingToFavorites: Bool = false
    @State var selectedFavoriteColor: WebCatalogColor?
    @State var favoriteMemo: String = ""
    @State var isLinksMenuPresented: Bool = false

    @AppStorage(wrappedValue: true, "Events.Active.IsLatest") var isActiveEventLatest: Bool

    init(_ extendedInformation: ComiketCircleExtendedInformation,
         _ webCatalogInformation: WebCatalogCircle?) {
        self.extendedInformation = extendedInformation
        self.webCatalogInformation = webCatalogInformation
    }

    var body: some ToolbarContent {
        // Favorites button
        if isActiveEventLatest && authenticator.onlineState == .online {
            ToolbarItem(placement: .bottomBar) {
                Button {
                    isAddingToFavorites = true
                } label: {
                    if #available(iOS 26.0, *) {
                        Label("Shared.Favorite", systemImage: "star.fill")
                    } else {
                        ToolbarButtonLabel("Shared.Favorite", imageName: "star.fill")
                    }
                }
                .popover(isPresented: $isAddingToFavorites, arrowEdge: .bottom) {
                    FavoritePopover(
                        initialColor: selectedFavoriteColor,
                        initialMemo: favoriteMemo,
                        isExistingFavorite: favorites.contains(webCatalogID: extendedInformation.webCatalogID),
                        onSave: { color, memo in
                            Task.detached {
                                await saveFavorite(color: color, memo: memo)
                            }
                            isAddingToFavorites = false
                        },
                        onDelete: {
                            Task.detached {
                                await deleteFavorite()
                            }
                            isAddingToFavorites = false
                        }
                    )
                }
                .onAppear {
                    reloadFavoriteColor()
                }
                .onChange(of: extendedInformation.webCatalogID) {
                    reloadFavoriteColor()
                }
            }
        }

        // Spacer
        if #available(iOS 26.0, *) {
            ToolbarSpacer(.flexible, placement: .bottomBar)
        } else {
            ToolbarItem(placement: .bottomBar) {
                Spacer()
            }
        }

        // Links menu (only show if there are links)
        if let webCatalogInformation, !webCatalogInformation.onlineStores.isEmpty {
            if #available(iOS 26.0, *) {
                ToolbarSpacer(.fixed, placement: .bottomBar)
            }

            ToolbarItem(placement: .bottomBar) {
                Menu {
                    ForEach(webCatalogInformation.onlineStores, id: \.link) { onlineStore in
                        Button(onlineStore.name) {
                            if let url = URL(string: onlineStore.link) {
                                openURL(url)
                            }
                        }
                    }
                } label: {
                    if #available(iOS 26.0, *) {
                        Label("Shared.Links", systemImage: "link")
                    } else {
                        ToolbarButtonLabel("Shared.Links", imageName: "link")
                    }
                }
            }
        }

        // SNS buttons
        if extendedInformation.twitterURL != nil ||
           extendedInformation.pixivURL != nil ||
           extendedInformation.circleMsPortalURL != nil {
            if #available(iOS 26.0, *) {
                ToolbarSpacer(.fixed, placement: .bottomBar)
            }

            if let circleMsPortalURL = extendedInformation.circleMsPortalURL {
                ToolbarItem(placement: .bottomBar) {
                    SNSButton(circleMsPortalURL, showsLabel: false, type: .circleMs)
                }
            }

            if let pixivURL = extendedInformation.pixivURL {
                ToolbarItem(placement: .bottomBar) {
                    SNSButton(pixivURL, showsLabel: false, type: .pixiv)
                }
            }

            if let twitterURL = extendedInformation.twitterURL {
                ToolbarItem(placement: .bottomBar) {
                    SNSButton(twitterURL, showsLabel: false, type: .twitter)
                }
            }
        }

    }

    func reloadFavoriteColor() {
        selectedFavoriteColor = favorites.wcIDMappedItems?[extendedInformation.webCatalogID]?.favorite.color
        favoriteMemo = favorites.wcIDMappedItems?[extendedInformation.webCatalogID]?.favorite.memo ?? ""
    }

    func saveFavorite(color: WebCatalogColor, memo: String) async {
        if let token = authenticator.token {
            let actor = FavoritesActor(modelContainer: sharedModelContainer)
            let favoritesAddResult = await actor.add(
                extendedInformation.webCatalogID,
                to: color,
                memo: memo,
                authToken: token
            )
            if favoritesAddResult {
                let (items, wcIDMappedItems) = await actor.all(authToken: token)
                await MainActor.run {
                    favorites.items = items
                    favorites.wcIDMappedItems = wcIDMappedItems
                    selectedFavoriteColor = color
                    favoriteMemo = memo
                }
            }
        }
    }

    func deleteFavorite() async {
        if let token = authenticator.token {
            let actor = FavoritesActor(modelContainer: sharedModelContainer)
            let favoritesDeleteResult = await actor.delete(
                extendedInformation.webCatalogID,
                authToken: token
            )
            if favoritesDeleteResult {
                let (items, wcIDMappedItems) = await actor.all(authToken: token)
                await MainActor.run {
                    favorites.items = items
                    favorites.wcIDMappedItems = wcIDMappedItems
                    selectedFavoriteColor = nil
                    favoriteMemo = ""
                }
            }
        }
    }
}
