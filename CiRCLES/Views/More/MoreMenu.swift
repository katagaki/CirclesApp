//
//  MoreMenu.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2025/11/02.
//

import SwiftUI

struct MoreMenu: View {

    @Binding var viewPath: [UnifiedPath]

    @AppStorage(wrappedValue: false, "Map.ShowsGenreOverlays") var showGenreOverlay: Bool
    @AppStorage(wrappedValue: true, "Customization.UseDarkModeMaps") var useDarkModeMaps: Bool
    @AppStorage(wrappedValue: true, "Customization.UseHighResolutionMaps") var useHighResolutionMaps: Bool
    @AppStorage(wrappedValue: false, "Customization.ShowSpaceName") var showSpaceName: Bool
    @AppStorage(wrappedValue: false, "Customization.ShowDay") var showDay: Bool
    @AppStorage(wrappedValue: false, "Customization.ShowWebCut") var showWebCut: Bool

    var body: some View {
        Menu("Tab.More", systemImage: "ellipsis") {
            Section {
                Toggle("More.Customization.Map.ShowsGenreOverlays", isOn: $showGenreOverlay)
                Toggle("More.Customization.Map.UseDarkModeMap", isOn: $useDarkModeMaps)
                Toggle("More.Customization.Map.UseHighDefinitionMap", isOn: $useHighResolutionMaps)
            } header: {
                Text("More.Customization.Map")
            }
            Section {
                Toggle("More.Customization.Circles.ShowWebCut", isOn: $showWebCut)
                Toggle("More.Customization.Circles.ShowHallAndBlock", isOn: $showSpaceName)
                Toggle("More.Customization.Circles.ShowDay", isOn: $showDay)
            } header: {
                Text("More.Customization.Circles")
            }
            Section {
                switch Locale.current.language.languageCode {
                case .japanese:
                    if UIApplication.shared.canOpenURL(URL(string: "maps://")!) {
                        ExternalLink("maps://?saddr=現在地&daddr=東京ビッグサイト",
                                     title: "More.Navigate.Maps", image: "ListIcon.AppleMaps")
                    }
                    if UIApplication.shared.canOpenURL(URL(string: "comgooglemaps://")!) {
                        ExternalLink("comgooglemaps://?saddr=現在地&daddr=東京ビッグサイト",
                                     title: "More.Navigate.GoogleMaps", image: "ListIcon.GoogleMaps")
                    }
                    if UIApplication.shared.canOpenURL(URL(string: "yjmap://")!) {
                        ExternalLink("yjmap://route/train?from=現在地&to=東京ビッグサイト",
                                     title: "More.Navigate.YahooMap", image: "ListIcon.YahooMap")
                    }
                default:
                    if UIApplication.shared.canOpenURL(URL(string: "maps://")!) {
                        ExternalLink("maps://?saddr=Current+Location&daddr=Tokyo+Big+Sight",
                                     title: "More.Navigate.Maps", image: "ListIcon.AppleMaps")
                    }
                    if UIApplication.shared.canOpenURL(URL(string: "comgooglemaps://")!) {
                        ExternalLink("comgooglemaps://?saddr=My+Location&daddr=Tokyo+Big+Sight",
                                     title: "More.Navigate.GoogleMaps", image: "ListIcon.GoogleMaps")
                    }
                }
            } header: {
                Text("More.Navigate")
            }
            Section {
                switch Locale.current.language.languageCode {
                case .japanese:
                    SafariLink("https://webcatalog.circle.ms",
                               title: "More.UsefulResources.WebCatalog", image: "ListIcon.WebCatalog")
                    SafariLink("https://comiket.co.jp",
                               title: "More.UsefulResources.Comiket", image: "ListIcon.Comiket")
                    SafariLink("https://www.bigsight.jp/visitor/floormap/",
                               title: "More.UsefulResources.BigSightMap", image: "ListIcon.BigSight")
                default:
                    SafariLink("https://int.webcatalog.circle.ms/en/catalog",
                               title: "More.UsefulResources.WebCatalog", image: "ListIcon.WebCatalog")
                    SafariLink("https://comiket.co.jp",
                               title: "More.UsefulResources.Comiket", image: "ListIcon.Comiket")
                    SafariLink("https://www.bigsight.jp/english/visitor/floormap/",
                               title: "More.UsefulResources.BigSightMap", image: "ListIcon.BigSight")
                }
            } header: {
                Text("More.UsefulResources")
            }
            Button("Tab.More", systemImage: "ellipsis") {
                self.viewPath.append(.more)
            }
        }
        .menuActionDismissBehavior(.disabled)
    }
}
