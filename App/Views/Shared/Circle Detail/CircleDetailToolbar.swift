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
    @Binding var favoriteMemo: String

    @State var isFavoritesPopoverPresented: Bool = false
    @State var isCallingFavoritesAPI: Bool = false
    @State var selectedFavoriteColor: WebCatalogColor?
    @State var isLinksMenuPresented: Bool = false

    @AppStorage(wrappedValue: true, "Events.Active.IsLatest") var isActiveEventLatest: Bool

    var body: some ToolbarContent {
        // Favorites button
        if isActiveEventLatest && authenticator.onlineState == .online {
            ToolbarItem(placement: .bottomBar) {
                if isCallingFavoritesAPI {
                    ProgressView()
                } else {
                    Button {
                        isFavoritesPopoverPresented = true
                    } label: {
                        ToolbarButtonLabel("Shared.Favorite", image: .system("star.fill"))
                    }
                    #if targetEnvironment(macCatalyst)
                    .sheet(isPresented: $isFavoritesPopoverPresented) {
                        favoritesPopover()
                            .presentationSizing(.fitted)
                            .interactiveDismissDisabled(false)
                    }
                    #else
                    .popover(isPresented: $isFavoritesPopoverPresented, arrowEdge: .bottom) {
                        favoritesPopover()
                    }
                    #endif
                    .onAppear {
                        reloadFavoriteColor()
                    }
                    .onChange(of: extendedInformation.webCatalogID) {
                        reloadFavoriteColor()
                    }
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
                    ToolbarButtonLabel("Shared.Links", image: .system("link"))
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

    @ViewBuilder
    func favoritesPopover() -> some View {
        FavoritePopover(
            initialColor: selectedFavoriteColor,
            initialMemo: favoriteMemo,
            isExistingFavorite: favorites.contains(webCatalogID: extendedInformation.webCatalogID),
            onSave: { color, memo in
                isCallingFavoritesAPI = true
                Task.detached {
                    await saveFavorite(color: color, memo: memo)
                    await MainActor.run {
                        isCallingFavoritesAPI = false
                    }
                }
                isFavoritesPopoverPresented = false
            },
            onDelete: {
                isCallingFavoritesAPI = true
                Task.detached {
                    await deleteFavorite()
                    await MainActor.run {
                        isCallingFavoritesAPI = false
                    }
                }
                isFavoritesPopoverPresented = false
            }
        )
    }
}
