import SwiftUI

struct HubPanel: View {

    @Environment(Harness.self) var harness
    @Binding var showsMe: Bool
    @State var segment: HubSegment = .circles
    @State var filter: HubFilter = .all
    @State var path = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {
            Group {
                switch segment {
                case .circles: HubCirclesView(filter: $filter)
                case .buys: HubBuysView()
                }
            }
            .safeAreaInset(edge: .top, spacing: 0.0) {
                HubPanelHeader(segment: $segment, path: $path)
            }
            .toolbarVisibility(.hidden, for: .navigationBar)
            .featureDestinations()
        }
        .sheet(isPresented: $showsMe) {
            HubMeSheet()
                .environment(harness)
        }
        .task {
            switch harness.launchScreen {
            case "favorites": filter = .favorites
            case "buys": segment = .buys
            case "me":
                try? await Task.sleep(for: .milliseconds(600))
                showsMe = true
            default: break
            }
        }
    }
}
