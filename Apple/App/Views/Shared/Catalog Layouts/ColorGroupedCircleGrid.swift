import SwiftUI
import TipKit
import RADiUS
import AXiS

struct ColorGroupedCircleGrid: View {

    let gridSpacing: CGFloat = 1.0

    @Binding var columns: Int
    var groups: [String: [ComiketCircle]]
    var showsOverlayWhenEmpty: Bool = true
    var namespace: Namespace.ID
    var onSelect: ((ComiketCircle) -> Void)
    var onDoubleTap: ((ComiketCircle) -> Void)?

    @AppStorage(wrappedValue: true, "Customization.ShowSpaceName") var showSpaceName: Bool
    @AppStorage(wrappedValue: false, "Customization.ShowDay") var showDay: Bool
    @AppStorage(wrappedValue: false, "Customization.ShowWebCut") var showWebCut: Bool

    @State var width: CGFloat = 0.0

    var gridItems: [GridItem] {
        Array(
            repeating: GridItem(.flexible(), spacing: gridSpacing),
            count: GridDisplayMode.displayedColumns(columns, width: width)
        )
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0.0) {
                ForEach(WebCatalogColor.allCases, id: \.self) { color in
                    if let circles = groups[String(color.rawValue)] {
                        if color == .uncolored && !circles.isEmpty {
                            WebCatalogFavoriteNotice()
                        }
                        LazyVGrid(columns: gridItems, spacing: gridSpacing) {
                            ForEach(Array(circles.enumerated()), id: \.element.id) { index, circle in
                                if let onDoubleTap {
                                    CircleCutImage(
                                        circle, in: namespace, cutType: showWebCut ? .web : .catalog,
                                        displayMode: GridDisplayMode(nearestTo: columns),
                                        showSpaceName: $showSpaceName, showDay: $showDay
                                    )
                                    .matchedGeometryEffect(id: "\(circle.id).Cut", in: namespace)
                                    .onFastDoubleTap(doubleTap: {
                                        onDoubleTap(circle)
                                    }, singleTap: {
                                        onSelect(circle)
                                    })
                                    .contextMenu(circle: circle) {
                                        onSelect(circle)
                                    }
                                    .matchedTransitionSource(id: circle.id, in: namespace)
                                    .pinchAnchor(id: circle.id)
                                    .popoverTip(index == 0 ? DoubleTapVisitTip() : nil)
                                } else {
                                    Button {
                                        onSelect(circle)
                                    } label: {
                                        CircleCutImage(
                                            circle, in: namespace, cutType: showWebCut ? .web : .catalog,
                                            displayMode: GridDisplayMode(nearestTo: columns),
                                            showSpaceName: $showSpaceName, showDay: $showDay
                                        )
                                        .matchedGeometryEffect(id: "\(circle.id).Cut", in: namespace)
                                    }
                                    .contextMenu(circle: circle) {
                                        onSelect(circle)
                                    }
                                    .matchedTransitionSource(id: circle.id, in: namespace)
                                    .pinchAnchor(id: circle.id)
                                }
                            }
                        }
                        .background(color.backgroundColor().tertiary)
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
        .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { width = $0 }
        .pinchToResize(
            $columns,
            levels: Array(GridDisplayMode.columnRange),
            itemHeight: itemHeight(columns:width:)
        )
        .overlay {
            if groups.isEmpty && showsOverlayWhenEmpty {
                ContentUnavailableView(
                    "Circles.NoCircles",
                    systemImage: "questionmark.square.dashed",
                    description: Text("Circles.NoCircles.Description")
                )
            }
        }
        .frame(maxHeight: .infinity)
    }

    func itemHeight(columns: Int, width: CGFloat) -> CGFloat {
        let displayedColumns = GridDisplayMode.displayedColumns(columns, width: width)
        let itemWidth = (width - gridSpacing * CGFloat(displayedColumns - 1)) / CGFloat(displayedColumns)
        return itemWidth * 256.0 / 180.0
    }
}
