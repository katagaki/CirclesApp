//
//  UnifiedMoreMenu.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2025/11/02.
//

import SwiftUI

struct UnifiedMoreMenu: View {

    @Environment(\.openURL) var openURL
    @Environment(Authenticator.self) var authenticator
    @Environment(Events.self) var planner
    @Environment(Unifier.self) var unifier

    @Binding var viewPath: [UnifiedPath]
    @Binding var isGoingToSignOut: Bool

    @State var activeEventNumber: Int = -1

    // Map Settings
    @AppStorage(wrappedValue: 1.9, "Map.ZoomFactor") var zoomFactor: Double
    @AppStorage(wrappedValue: false, "Map.ShowsGenreOverlays") var showGenreOverlay: Bool
    @AppStorage(wrappedValue: true, "Customization.UseDarkModeMaps") var useDarkModeMaps: Bool
    @AppStorage(wrappedValue: true, "Customization.UseHighResolutionMaps") var useHighResolutionMaps: Bool

    // Circle Display Settings
    @AppStorage(wrappedValue: false, "Customization.ShowSpaceName") var showSpaceName: Bool
    @AppStorage(wrappedValue: false, "Customization.ShowDay") var showDay: Bool
    @AppStorage(wrappedValue: false, "Customization.ShowWebCut") var showWebCut: Bool

    // Others
    @AppStorage(wrappedValue: false, "PrivacyMode.On") var isPrivacyModeOn: Bool

    var body: some View {
        Menu("Tab.More", systemImage: "ellipsis") {
            Section {
                if let eventData = planner.eventData {
                    Picker(selection: $activeEventNumber) {
                        ForEach(eventData.list.sorted(by: {$0.number > $1.number}), id: \.id) { event in
                            Text("Shared.Event.\(event.number)")
                                .tag(event.number)
                        }
                    } label: {
                        Text("My.Events.SelectEvent")
                    }
                    .pickerStyle(.menu)
                    .disabled(authenticator.onlineState == .offline ||
                              authenticator.onlineState == .undetermined)
                } else {
                    Text("My.Events.OfflineMode")
                        .foregroundStyle(.secondary)
                }
            }
            ControlGroup("More.Customization.Map") {
                Button("Shared.Zoom.Out", systemImage: "minus") {
                    zoomFactor = min(10.0, zoomFactor + 0.3)
                }
                .disabled(zoomFactor >= 10.0)
                Button("Shared.Zoom.In", systemImage: "plus") {
                    zoomFactor = max(0.5, zoomFactor - 0.3)
                }
                .disabled(zoomFactor <= 0.5)
            }
            Section {
                Toggle("More.Customization.Map.ShowsGenreOverlays", systemImage: "theatermasks",
                       isOn: $showGenreOverlay)
                Toggle("More.Customization.Map.UseDarkModeMap", systemImage: "moon",
                       isOn: $useDarkModeMaps)
                Toggle("More.Customization.Map.UseHighDefinitionMap", systemImage: "square.resize.up",
                       isOn: $useHighResolutionMaps)
            }
            Section {
                Toggle("More.Customization.Circles.ShowWebCut", systemImage: "text.rectangle.page",
                       isOn: $showWebCut)
                Toggle("More.Customization.Circles.ShowHallAndBlock", systemImage: "building",
                       isOn: $showSpaceName)
                Toggle("More.Customization.Circles.ShowDay", systemImage: "calendar",
                       isOn: $showDay)
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
            Section {
                Button("Shared.Logout") {
                    unifier.hide()
                    Task {
                        try? await Task.sleep(for: .seconds(0.5))
                        isGoingToSignOut = true
                    }
                }
                Button("More.DeleteAccount", role: .destructive) {
                    openURL(URL(string: "https://auth2.circle.ms/Account/WithDraw1")!)
                }
            } header: {
                Text("More.Account")
            }
            Section {
                Toggle("More.PrivacyMode.On", systemImage: "eye.slash",
                       isOn: $isPrivacyModeOn)
                Button("More.More", systemImage: "ellipsis") {
                    unifier.hide()
                    self.viewPath.append(.more)
                }
            } header: {
                Text("More.More")
            }
        }
        .menuActionDismissBehavior(.disabled)
        .onAppear {
            activeEventNumber = planner.activeEventNumber
        }
        .onChange(of: activeEventNumber) { oldValue, _ in
            if oldValue != -1 {
                planner.activeEventNumber = activeEventNumber
            }
        }
    }
}
