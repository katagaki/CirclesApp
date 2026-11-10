import SwiftUI

private let navigateMapsJPURL = "maps://?saddr=現在地&daddr=東京ビッグサイト"
private let navigateGoogleMapsJPURL = "comgooglemaps://?saddr=現在地&daddr=東京ビッグサイト"
private let navigateYahooMapJPURL = "yjmap://route/train?from=現在地&to=東京ビッグサイト"
private let navigateMapsENURL = "maps://?saddr=Current+Location&daddr=Tokyo+Big+Sight"
private let navigateGoogleMapsENURL = "comgooglemaps://?saddr=My+Location&daddr=Tokyo+Big+Sight"

struct MyDirectionsSection: View {

    struct Destination: Identifiable {
        let title: String
        let image: String
        let url: String
        var id: String { title }
    }

    var destinations: [Destination] {
        let isJapanese = Locale.current.language.languageCode == .japanese
        var destinations: [Destination] = []
        if UIApplication.shared.canOpenURL(URL(string: "maps://")!) {
            destinations.append(Destination(title: "More.Navigate.Maps", image: "ListIcon.AppleMaps",
                                            url: isJapanese ? navigateMapsJPURL : navigateMapsENURL))
        }
        if UIApplication.shared.canOpenURL(URL(string: "comgooglemaps://")!) {
            destinations.append(Destination(title: "More.Navigate.GoogleMaps", image: "ListIcon.GoogleMaps",
                                            url: isJapanese ? navigateGoogleMapsJPURL : navigateGoogleMapsENURL))
        }
        if isJapanese, UIApplication.shared.canOpenURL(URL(string: "yjmap://")!) {
            destinations.append(Destination(title: "More.Navigate.YahooMap", image: "ListIcon.YahooMap",
                                            url: navigateYahooMapJPURL))
        }
        return destinations
    }

    var body: some View {
        let destinations = destinations
        if !destinations.isEmpty {
            Section {
                ForEach(destinations) { destination in
                    Link(destination: URL(string: destination.url)!) {
                        HStack {
                            ListIconLabel(title: LocalizedStringKey(destination.title), image: destination.image)
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                                .foregroundStyle(.foreground.opacity(0.5))
                        }
                    }
                    .tint(.primary)
                }
            } header: {
                Text("More.Navigate")
            }
        }
    }
}
