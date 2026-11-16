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
    @State var noticeHeight: CGFloat = 0.0

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

    var presentColors: [WebCatalogColor] {
        WebCatalogColor.allCases.filter { groups[String($0.rawValue)] != nil }
    }

    var pinchSections: [PinchZoomSection] {
        presentColors.map { color in
            let circles = groups[String(color.rawValue)] ?? []
            return PinchZoomSection(
                count: circles.count,
                leading: color == .uncolored && !circles.isEmpty ? noticeHeight : 0.0,
                background: AnyShapeStyle(color.backgroundColor().tertiary)
            )
        }
    }

    var body: some View {
        ScrollView {
            PinchZoomGrid(
                columnCount: displayedColumns,
                columnCounts: columnCounts,
                sections: pinchSections,
                spacing: gridSpacing,
                heightRatio: 256.0 / 180.0,
                onColumnCountChange: setDisplayedColumns
            ) {
                WebCatalogFavoriteNotice()
            } cell: { section, index in
                if let circles = groups[String(presentColors[section].rawValue)] {
                    pinchCell(circles[index])
                }
            } content: {
                VStack(alignment: .leading, spacing: 0.0) {
                    ForEach(WebCatalogColor.allCases, id: \.self) { color in
                        if let circles = groups[String(color.rawValue)] {
                            if color == .uncolored && !circles.isEmpty {
                                WebCatalogFavoriteNotice()
                                    .onGeometryChange(for: CGFloat.self) { $0.size.height } action: {
                                        noticeHeight = $0
                                    }
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
                            .background(color.backgroundColor().tertiary)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { width = $0 }
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
