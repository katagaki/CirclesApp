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

    @Namespace var pinchNamespace

    var displayedColumns: Int {
        GridDisplayMode.displayedColumns(columns, width: width)
    }

    var columnCounts: [Int] {
        GridDisplayMode.columnRange.map { GridDisplayMode.displayedColumns($0, width: width) }
    }

    var gridItems: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: gridSpacing), count: displayedColumns)
    }

    var body: some View {
        ScrollView {
            PinchZoomGrid(
                columnCount: displayedColumns,
                columnCounts: columnCounts,
                sections: [PinchZoomSection(count: circles.count)],
                spacing: gridSpacing,
                heightRatio: 256.0 / 180.0,
                onColumnCountChange: setDisplayedColumns
            ) { _, index in
                pinchCell(circles[index])
            } content: {
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
                        }
                    }
                }
            }
        }
        .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { width = $0 }
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

    func setDisplayedColumns(_ displayedColumns: Int) {
        if let match = GridDisplayMode.columnRange.first(where: {
            GridDisplayMode.displayedColumns($0, width: width) == displayedColumns
        }) {
            columns = match
        }
    }

    func pinchCell(_ circle: ComiketCircle) -> some View {
        CircleCutImage(
            circle, in: pinchNamespace, cutType: showWebCut ? .web : .catalog,
            displayMode: GridDisplayMode(nearestTo: columns),
            showSpaceName: $showSpaceName, showDay: $showDay
        )
    }
}
