import SwiftUI

enum MapApproach: Int, CaseIterable, Identifiable {
    case step
    case focus
    case panZoom
    case overview
    case directions

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .step: return "Step & Tap"
        case .focus: return "Focus"
        case .panZoom: return "Pan & Zoom"
        case .overview: return "Overview"
        case .directions: return "Text Only"
        }
    }

    var summary: String {
        switch self {
        case .step: return "Crown steps circle to circle, tap to select"
        case .focus: return "Auto-centred crop, crown widens context"
        case .panZoom: return "Full map, drag to pan, crown to zoom"
        case .overview: return "Whole hall, crown steps through favorites"
        case .directions: return "No navigation, just the space number"
        }
    }
}

struct MapComparisonView: View {

    let favorite: Favorite

    @State private var approach: MapApproach = .step

    var body: some View {
        TabView(selection: $approach) {
            ForEach(MapApproach.allCases) { item in
                page(for: item)
                    .tag(item)
            }
        }
        .tabViewStyle(.verticalPage)
        .navigationTitle(approach.title)
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private func page(for approach: MapApproach) -> some View {
        switch approach {
        case .step: StepMapView(favorite: favorite)
        case .focus: FocusMapView(favorite: favorite)
        case .panZoom: PanZoomMapView(favorite: favorite)
        case .overview: OverviewMapView(favorite: favorite)
        case .directions: DirectionsView(favorite: favorite)
        }
    }
}
