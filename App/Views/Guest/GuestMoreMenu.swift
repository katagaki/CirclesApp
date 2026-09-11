import ORBiT
import SwiftUI

private let navigateMapsJPURL = "maps://?saddr=現在地&daddr=東京ビッグサイト"
private let navigateGoogleMapsJPURL = "comgooglemaps://?saddr=現在地&daddr=東京ビッグサイト"
private let navigateYahooMapJPURL = "yjmap://route/train?from=現在地&to=東京ビッグサイト"
private let navigateMapsENURL = "maps://?saddr=Current+Location&daddr=Tokyo+Big+Sight"
private let navigateGoogleMapsENURL = "comgooglemaps://?saddr=My+Location&daddr=Tokyo+Big+Sight"
private let webCatalogJPURL = "https://webcatalog.circle.ms"
private let webCatalogENURL = "https://int.webcatalog.circle.ms"
private let comiketURL = "https://comiket.co.jp"
private let bigSightMapJPURL = "https://www.bigsight.jp/visitor/floormap/"
private let bigSightMapENURL = "https://www.bigsight.jp/english/visitor/floormap/"
private let sourceCodeURL = "https://github.com/katagaki/CirclesApp"

/// `UnifiedMoreMenu` with everything a guest cannot reach taken out.
///
/// Gone: the event database and backup screens, every map and circle display toggle, and
/// the whole account section — all of them act on a catalog or a circle.ms login a guest
/// does not have. What survives is what works with no account at all: getting to the
/// venue, the public Comiket links, and the way back out of Guest Mode.
struct GuestMoreMenu: View {

    @Environment(\.openURL) var openURL
    @Environment(SharedBuysSession.self) var sharedBuys

    @Binding var stackPath: [UnifiedPath]

    @State private var isConfirmingExit: Bool = false

    var body: some View {
        Menu("Tab.More", systemImage: "ellipsis") {
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
            Section {
                Button("More.Guest.Exit") {
                    isConfirmingExit = true
                }
            } header: {
                Text("More.Account")
            }
            Section {
                Button("More.GitHub", systemImage: "chevron.left.forwardslash.chevron.right") {
                    openURL(URL(string: sourceCodeURL)!)
                }
                Button("More.Attributions") {
                    stackPath.append(.moreAttributions)
                }
            } header: {
                Text("More.More")
            }
        }
        .menuActionDismissBehavior(.disabled)
        .alert("Alerts.Guest.Exit.Title", isPresented: $isConfirmingExit) {
            Button("More.Guest.Exit", role: .destructive) {
                sharedBuys.exitGuestMode()
            }
            Button("Shared.Cancel", role: .cancel) { }
        } message: {
            Text("Alerts.Guest.Exit.Message")
        }
    }
}
