//
//  UnifiedMoreMenu.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2025/11/02.
//

import SwiftUI

private let navigateMapsJPURL = "maps://?saddr=現在地&daddr=東京ビッグサイト"
private let navigateGoogleMapsJPURL = "comgooglemaps://?saddr=現在地&daddr=東京ビッグサイト"
private let navigateYahooMapJPURL = "yjmap://route/train?from=現在地&to=東京ビッグサイト"
private let navigateMapsENURL = "maps://?saddr=Current+Location&daddr=Tokyo+Big+Sight"
private let navigateGoogleMapsENURL = "comgooglemaps://?saddr=My+Location&daddr=Tokyo+Big+Sight"
private let webCatalogJPURL = "https://webcatalog.circle.ms"
private let comiketURL = "https://comiket.co.jp"
private let bigSightMapJPURL = "https://www.bigsight.jp/visitor/floormap/"
private let webCatalogENURL = "https://int.webcatalog.circle.ms/en/catalog"
private let bigSightMapENURL = "https://www.bigsight.jp/english/visitor/floormap/"
private let deleteAccountURL = "https://auth2.circle.ms/Account/WithDraw1"
private let sourceCodeURL = "https://github.com/katagaki/CirclesApp"

struct UnifiedMoreMenu: View {

    @Environment(\.openURL) var openURL
    @Environment(Authenticator.self) var authenticator
    @Environment(Unifier.self) var unifier
    @Environment(BackupManager.self) var backupManager

    // Map Settings

    @AppStorage(wrappedValue: false, "Map.ShowsGenreOverlays") var showGenreOverlay: Bool
    @AppStorage(wrappedValue: true, "Customization.UseDarkModeMaps") var useDarkModeMaps: Bool
    @AppStorage(wrappedValue: true, "Customization.UseHighResolutionMaps") var useHighResolutionMaps: Bool
    @AppStorage(wrappedValue: .none, "Map.ScrollType") var scrollType: MapAutoScrollType

    // Circle Display Settings
    @AppStorage(wrappedValue: true, "Customization.ShowSpaceName") var showSpaceName: Bool
    @AppStorage(wrappedValue: false, "Customization.ShowDay") var showDay: Bool
    @AppStorage(wrappedValue: false, "Customization.ShowWebCut") var showWebCut: Bool
    @AppStorage(wrappedValue: true, "Customization.DoubleTapToVisit") var isDoubleTapToVisitEnabled: Bool
    @AppStorage(wrappedValue: true, "Customization.UseZoomTransition") var useZoomTransition: Bool

    // Others
    @AppStorage(wrappedValue: false, "PrivacyMode.On") var isPrivacyModeOn: Bool

    var body: some View {
        Menu("Tab.More", systemImage: "ellipsis") {
            Section {
                Button("ViewTitle.More.DBAdmin", systemImage: "externaldrive") {
                    unifier.hide()
                    unifier.stackPath.append(.moreEventData)
                }
            }

            Section {
                Menu("More.Customization.Map", systemImage: "map") {
                    Toggle("More.Customization.Map.ShowsGenreOverlays", systemImage: "theatermasks",
                           isOn: $showGenreOverlay)
                    Toggle("More.Customization.Map.UseDarkModeMap", systemImage: "moon",
                           isOn: $useDarkModeMaps)
                    Toggle("More.Customization.Map.UseHighDefinitionMap", systemImage: "square.resize.up",
                           isOn: $useHighResolutionMaps)
                    Toggle("More.Customization.Map.ScrollToSelection",
                           systemImage: "arrow.up.and.down.and.arrow.left.and.right",
                           isOn: Binding(
                               get: { scrollType == .popover },
                               set: { scrollType = $0 ? .popover : .none }
                           ))
                }
                .menuActionDismissBehavior(.disabled)
                Menu("More.Customization.Circles", systemImage: "square.grid.2x2") {
                    Toggle("More.Customization.Circles.ShowWebCut", systemImage: "text.rectangle.page",
                           isOn: $showWebCut)
                    Toggle("More.Customization.Circles.ShowHallAndBlock", systemImage: "table.furniture",
                           isOn: $showSpaceName)
                    Toggle("More.Customization.Circles.ShowDay", systemImage: "calendar",
                           isOn: $showDay)
                    Toggle("More.Customization.Circles.DoubleTapToVisit", systemImage: "hand.tap",
                           isOn: $isDoubleTapToVisitEnabled)
                    Toggle("More.Customization.Circles.UseZoomTransition", systemImage: "arrow.up.backward.and.arrow.down.forward",
                           isOn: $useZoomTransition)
                }
                .menuActionDismissBehavior(.disabled)
                Menu("More.Backup", systemImage: "icloud") {
                    Section {
                        Toggle("More.Backup.Enabled", systemImage: "arrow.trianglehead.2.clockwise.rotate.90.icloud",
                               isOn: Binding(
                                   get: { backupManager.isEnabled },
                                   set: { backupManager.isEnabled = $0 }
                               ))
                        .disabled(backupManager.isBackingUp || backupManager.isRestoring)
                        if backupManager.isEnabled {
                            Button("More.Backup.Now", systemImage: "arrow.up.circle") {
                                if let pid = backupManager.pid {
                                    Task { await backupManager.backup(pid: pid) }
                                }
                            }
                            .disabled(backupManager.pid == nil
                                      || backupManager.isBackingUp || backupManager.isRestoring)
                        }
                        if backupManager.pid != nil && backupManager.lastBackupDate != nil {
                            Button("More.Backup.Restore", systemImage: "arrow.down.circle") {
                                backupManager.promptRestore()
                            }
                            .disabled(backupManager.isBackingUp || backupManager.isRestoring)
                        }
                    } footer: {
                        if backupManager.lastBackupFailed {
                            Text("More.Backup.Failed")
                        } else if let lastBackupDate = backupManager.lastBackupDate {
                            let formatted = lastBackupDate.formatted(date: .abbreviated, time: .shortened)
                            Text("More.Backup.LastBackedUp \(formatted)")
                        } else {
                            Text("More.Backup.NeverBackedUp")
                        }
                    }
                }
                .labelsVisibility(.visible)
                .menuActionDismissBehavior(.disabled)
            }
            if !authenticator.isOfflineModeActive {
                Section {
                    Menu("More.UsefulResources", systemImage: "info.circle") {
                        Section {
                            if Locale.current.language.languageCode == .japanese {
                                if UIApplication.shared.canOpenURL(URL(string: "maps://")!) {
                                    ExternalLink(navigateMapsJPURL,
                                                 title: "More.Navigate.Maps", image: "ListIcon.AppleMaps")
                                }
                                if UIApplication.shared.canOpenURL(URL(string: "comgooglemaps://")!) {
                                    ExternalLink(navigateGoogleMapsJPURL,
                                                 title: "More.Navigate.GoogleMaps", image: "ListIcon.GoogleMaps")
                                }
                                if UIApplication.shared.canOpenURL(URL(string: "yjmap://")!) {
                                    ExternalLink(navigateYahooMapJPURL,
                                                 title: "More.Navigate.YahooMap", image: "ListIcon.YahooMap")
                                }
                            } else {
                                if UIApplication.shared.canOpenURL(URL(string: "maps://")!) {
                                    ExternalLink(navigateMapsENURL,
                                                 title: "More.Navigate.Maps", image: "ListIcon.AppleMaps")
                                }
                                if UIApplication.shared.canOpenURL(URL(string: "comgooglemaps://")!) {
                                    ExternalLink(navigateGoogleMapsENURL,
                                                 title: "More.Navigate.GoogleMaps", image: "ListIcon.GoogleMaps")
                                }
                            }
                        } header: {
                            Text("More.Navigate")
                        }
                        Section {
                            if Locale.current.language.languageCode == .japanese {
                                SafariLink(webCatalogJPURL,
                                           title: "More.UsefulResources.WebCatalog", image: "ListIcon.WebCatalog")
                                SafariLink(comiketURL,
                                           title: "More.UsefulResources.Comiket", image: "ListIcon.Comiket")
                                SafariLink(bigSightMapJPURL,
                                           title: "More.UsefulResources.BigSightMap", image: "ListIcon.BigSight")
                            } else {
                                SafariLink(webCatalogENURL,
                                           title: "More.UsefulResources.WebCatalog", image: "ListIcon.WebCatalog")
                                SafariLink(comiketURL,
                                           title: "More.UsefulResources.Comiket", image: "ListIcon.Comiket")
                                SafariLink(bigSightMapENURL,
                                           title: "More.UsefulResources.BigSightMap", image: "ListIcon.BigSight")
                            }
                        } header: {
                            Text("More.UsefulResources.Links")
                        }
                    }
                    .labelsVisibility(.visible)
                }
            }
            Section {
                if authenticator.isOfflineModeActive {
                    Button("More.ExitOfflineMode") {
                        unifier.hide()
                        Task {
                            try? await Task.sleep(for: .seconds(0.5))
                            unifier.isGoingToExitOfflineMode = true
                        }
                    }
                } else {
                    if authenticator.canUseOfflineMode {
                        Button("More.EnterOfflineMode") {
                            unifier.hide()
                            Task {
                                try? await Task.sleep(for: .seconds(0.5))
                                unifier.isGoingToEnterOfflineMode = true
                            }
                        }
                    }
                    Button("Shared.Logout") {
                        unifier.hide()
                        Task {
                            try? await Task.sleep(for: .seconds(0.5))
                            unifier.isGoingToSignOut = true
                        }
                    }
                    Button("More.DeleteAccount", role: .destructive) {
                        openURL(URL(string: deleteAccountURL)!)
                    }
                }
            } header: {
                Text("More.Account")
            }
            Section {
                Toggle("More.PrivacyMode.On", systemImage: "eye.slash",
                       isOn: $isPrivacyModeOn)
                Button("More.GitHub", systemImage: "chevron.left.forwardslash.chevron.right") {
                    openURL(URL(string: sourceCodeURL)!)
                }
                Button("More.Attributions") {
                    unifier.hide()
                    unifier.stackPath.append(.moreAttributions)
                }
            } header: {
                Text("More.More")
            }
        }
        .menuActionDismissBehavior(.disabled)
    }
}
