//
//  CircleDetailToolbar.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2024/09/07.
//

import Komponents
import SwiftUI

struct CircleDetailToolbar: View {

    @Environment(Authenticator.self) var authenticator
    @Environment(Favorites.self) var favorites

    @Environment(\.openURL) var openURL

    var extendedInformation: ComiketCircleExtendedInformation
    @State var webCatalogInformation: WebCatalogCircle?

    @State var isAddingToFavorites: Bool = false
    @State var selectedFavoriteColor: WebCatalogColor?
    @State var favoriteMemo: String = ""

    @AppStorage(wrappedValue: true, "Events.Active.IsLatest") var isActiveEventLatest: Bool

    init(_ extendedInformation: ComiketCircleExtendedInformation,
         _ webCatalogInformation: WebCatalogCircle?) {
        self.extendedInformation = extendedInformation
        self.webCatalogInformation = webCatalogInformation
    }

    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8.0) {
                if isActiveEventLatest && authenticator.onlineState == .online {
                    FavoriteButton(
                        color: selectedFavoriteColor?.backgroundColor()
                    ) {
                        favorites.contains(webCatalogID: extendedInformation.webCatalogID)
                    } onSelect: {
                        isAddingToFavorites = true
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
                }
                HStack(spacing: 5.0) {
                    Group {
                        if let twitterURL = extendedInformation.twitterURL {
                            SNSButton(twitterURL, showsLabel: false, type: .twitter)
                        }
                        if let pixivURL = extendedInformation.pixivURL {
                            SNSButton(pixivURL, showsLabel: false, type: .pixiv)
                        }
                        if let circleMsPortalURL = extendedInformation.circleMsPortalURL {
                            SNSButton(circleMsPortalURL, showsLabel: false, type: .circleMs)
                        }
                    }
                }
                if let webCatalogInformation {
                    ForEach(webCatalogInformation.onlineStores, id: \.link) { onlineStore in
                        BarAccessoryButton(LocalizedStringKey(onlineStore.name)) {
                            if let url = URL(string: onlineStore.link) {
                                openURL(url)
                            }
                        }
                        .glassEffectIfSupported()
                    }
                }
            }
            .padding(.horizontal, 12.0)
        }
        .padding(
            .bottom,
            UIDevice.current.userInterfaceIdiom == .pad ?
            12.0 : 0.0
        )
        .scrollIndicators(.hidden)
        .onAppear {
            reloadFavoriteColor()
        }
        .onChange(of: extendedInformation.webCatalogID) {
            reloadFavoriteColor()
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
