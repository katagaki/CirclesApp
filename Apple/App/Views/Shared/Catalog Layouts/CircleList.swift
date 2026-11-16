import SwiftUI
import TipKit
import AXiS

struct CircleList: View {

    var circles: [ComiketCircle]
    var showsOverlayWhenEmpty: Bool = true
    @Binding var displayMode: ListDisplayMode
    var namespace: Namespace.ID
    var onSelect: ((ComiketCircle) -> Void)
    var onDoubleTap: ((ComiketCircle) -> Void)?

    @Environment(\.displayScale) var displayScale

    @Namespace var pinchNamespace

    let modes: [ListDisplayMode] = [.compact, .regular]

    var pinchSections: [PinchZoomSection] {
        [PinchZoomSection(count: circles.count)]
    }

    var body: some View {
        ScrollView {
            PinchZoomList(
                level: modes.firstIndex(of: displayMode) ?? 0,
                rowHeights: modes.map { $0.rowHeight + 1.0 / displayScale },
                sections: pinchSections,
                onLevelChange: setLevel
            ) { _, index, session, progress in
                let regularWeight = session.weight(of: 1, progress: progress)
                PinchZoomListRow(
                    circle: circles[index],
                    namespace: pinchNamespace,
                    regularWeight: regularWeight,
                    dividerLeading: 58.0 + 42.0 * regularWeight
                )
            } content: {
                LazyVStack(spacing: 0.0) {
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
                                .contentShape(.rect)
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
                                .buttonStyle(.plain)
                            }
                        }
                        .padding([.leading, .trailing], 20.0)
                        .padding([.top, .bottom], 10.0)
                        .contextMenu(circle: circle) {
                            onSelect(circle)
                        }
                        switch displayMode {
                        case .regular:
                            Divider()
                                .padding([.leading], 100.0)
                        case .compact:
                            Divider()
                                .padding([.leading], 58.0)
                        }
                    }
                }
                // HACK: A fresh stack measures every row anew instead of keeping the previous size's cached heights
                .id(displayMode)
            }
        }
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

    func setLevel(_ level: Int) {
        displayMode = modes[level]
    }
}
