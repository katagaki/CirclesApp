import SwiftUI
import TipKit
import AXiS

struct CircleGrid: View {

    let gridSpacing: CGFloat = 1.0

    @Binding var columns: Int
    var circles: [ComiketCircle]
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
        }
        .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { width = $0 }
        .pinchToResize(
            $columns,
            levels: Array(GridDisplayMode.columnRange),
            itemHeight: itemHeight(columns:width:)
        )
        .overlay {
            if circles.isEmpty && showsOverlayWhenEmpty {
                ContentUnavailableView(
                    "Circles.NoCircles",
                    systemImage: "questionmark.square.dashed",
                    description: Text("Circles.NoCircles.Description")
                )
            }
        }
    }

    func itemHeight(columns: Int, width: CGFloat) -> CGFloat {
        let displayedColumns = GridDisplayMode.displayedColumns(columns, width: width)
        let itemWidth = (width - gridSpacing * CGFloat(displayedColumns - 1)) / CGFloat(displayedColumns)
        return itemWidth * 256.0 / 180.0
    }
}
