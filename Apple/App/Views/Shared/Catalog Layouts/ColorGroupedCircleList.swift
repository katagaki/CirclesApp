import SwiftUI
import TipKit
import RADiUS
import AXiS

struct ColorGroupedCircleList: View {

    var groups: [String: [ComiketCircle]]
    var showsOverlayWhenEmpty: Bool = true
    @Binding var displayMode: ListDisplayMode
    var namespace: Namespace.ID
    var onSelect: ((ComiketCircle) -> Void)
    var onDoubleTap: ((ComiketCircle) -> Void)?

    @Environment(\.displayScale) var displayScale
    @State var noticeHeight: CGFloat = 0.0

    @Namespace var pinchNamespace

    let modes: [ListDisplayMode] = [.compact, .regular]

    var presentColors: [WebCatalogColor] {
        WebCatalogColor.allCases.filter { groups[String($0.rawValue)] != nil }
    }

    var pinchSections: [PinchZoomSection] {
        presentColors.map { color in
            let circles = groups[String(color.rawValue)] ?? []
            return PinchZoomSection(
                count: circles.count,
                leading: color == .uncolored && !circles.isEmpty ? noticeHeight : 0.0
            )
        }
    }

    var body: some View {
        ScrollView {
            PinchZoomList(
                level: modes.firstIndex(of: displayMode) ?? 0,
                rowHeights: modes.map { $0.rowHeight + 1.0 / displayScale },
                sections: pinchSections,
                onLevelChange: setLevel
            ) {
                WebCatalogFavoriteNotice()
            } row: { section, index, session, progress in
                if let circles = groups[String(presentColors[section].rawValue)] {
                    PinchZoomListRow(
                        circle: circles[index],
                        namespace: pinchNamespace,
                        regularWeight: session.weight(of: 1, progress: progress),
                        dividerLeading: 100.0,
                        background: background(of: section)
                    )
                }
            } content: {
                LazyVStack(spacing: 0.0, pinnedViews: [.sectionHeaders]) {
                    ForEach(WebCatalogColor.allCases, id: \.self) { color in
                        if let circles = groups[String(color.rawValue)] {
                            if color == .uncolored && !circles.isEmpty {
                                WebCatalogFavoriteNotice()
                                    .onGeometryChange(for: CGFloat.self) { $0.size.height } action: {
                                        noticeHeight = $0
                                    }
                            }
                            Section {
                                ForEach(Array(circles.enumerated()), id: \.element.id) { index, circle in
                                    Group {
                                        if let onDoubleTap {
                                            Group {
                                                switch displayMode {
                                                case .regular:
                                                    CircleListRegularRow(circle: circle, namespace: namespace)
                                                case .compact:
                                                    CircleListCompactRow(circle: circle, namespace: namespace)
                                                }
                                            }
                                            .contentShape(Rectangle())
                                            .onFastDoubleTap(doubleTap: {
                                                onDoubleTap(circle)
                                            }, singleTap: {
                                                onSelect(circle)
                                            })
                                            .popoverTip(index == 0 ? DoubleTapVisitTip() : nil)
                                        } else {
                                            Button {
                                                onSelect(circle)
                                            } label: {
                                                switch displayMode {
                                                case .regular:
                                                    CircleListRegularRow(circle: circle, namespace: namespace)
                                                case .compact:
                                                    CircleListCompactRow(circle: circle, namespace: namespace)
                                                }
                                            }
                                        }
                                    }
                                    .padding([.leading, .trailing], 20.0)
                                    .padding([.top, .bottom], 10.0)
                                    .contextMenu(circle: circle) {
                                        onSelect(circle)
                                    }
                                    .background(Rectangle().fill(color.backgroundColor().tertiary))
                                    Divider()
                                        .padding([.leading], 100.0)
                                        .background(Rectangle().fill(color.backgroundColor().tertiary))
                                }
                            }
                        }
                    }
                }
                // HACK: A fresh stack measures every row anew instead of keeping the previous size's cached heights
                .id(displayMode)
            }
        }
        .overlay {
            if groups.isEmpty && showsOverlayWhenEmpty {
                ContentUnavailableView(
                    "Circles.NoCircles",
                    systemImage: "questionmark.square.dashed",
                    description: Text("Circles.NoCircles.Description")
                )
            }
        }
    }

    func setLevel(_ level: Int) {
        displayMode = modes[level]
    }

    func background(of section: Int) -> AnyShapeStyle {
        AnyShapeStyle(presentColors[section].backgroundColor().tertiary)
    }
}
