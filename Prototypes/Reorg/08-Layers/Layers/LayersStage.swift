import SwiftUI

struct LayersStage<Panel: View, Chrome: View, Overlay: View>: View {

    @Environment(Harness.self) var harness
    @Environment(LayersState.self) var layers
    @Environment(\.colorScheme) var colorScheme

    @Binding var detent: PresentationDetent
    let detents: Set<PresentationDetent>
    let sheetMapInset: CGFloat
    let panelWidth: CGFloat
    let panel: () -> Panel
    let chrome: () -> Chrome
    let overlay: (HallMapLayout) -> Overlay

    init(
        detent: Binding<PresentationDetent>,
        detents: Set<PresentationDetent>,
        sheetMapInset: CGFloat = 120.0,
        panelWidth: CGFloat = 380.0,
        @ViewBuilder panel: @escaping () -> Panel,
        @ViewBuilder chrome: @escaping () -> Chrome,
        @ViewBuilder overlay: @escaping (HallMapLayout) -> Overlay
    ) {
        self._detent = detent
        self.detents = detents
        self.sheetMapInset = sheetMapInset
        self.panelWidth = panelWidth
        self.panel = panel
        self.chrome = chrome
        self.overlay = overlay
    }

    func sheetInset(in size: CGSize) -> CGFloat {
        detent == .height(sheetMapInset) ? sheetMapInset : size.height * 0.5
    }

    var body: some View {
        GeometryReader { proxy in
            let style = StageStyle.style(for: proxy.size.width)
            let resolvedPanelWidth = min(panelWidth, proxy.size.width * 0.48)
            ZStack(alignment: .topLeading) {
                HallMapView.floorColor(colorScheme)
                    .ignoresSafeArea()
                HallMapView()
                    .overlay {
                        GeometryReader { mapProxy in
                            overlay(HallMapLayout(hall: harness.hall, size: mapProxy.size))
                        }
                    }
                    .padding(.top, 104.0)
                    .padding(.bottom, style == .sheet ? sheetInset(in: proxy.size) : 0.0)
                    .padding(.leading, style == .panel ? resolvedPanelWidth + 20.0 : 0.0)
                    .ignoresSafeArea(edges: .bottom)
                    .animation(.smooth, value: detent)
                chrome()
                    .padding(.leading, style == .panel ? resolvedPanelWidth + 24.0 : 0.0)
                if style == .panel {
                    panel()
                        .frame(width: resolvedPanelWidth)
                        .frame(maxHeight: .infinity)
                        .clipShape(.rect(cornerRadius: 28.0))
                        .glassEffect(.regular, in: .rect(cornerRadius: 28.0))
                        .shadow(color: .black.opacity(0.12), radius: 16.0, y: 2.0)
                        .padding(.leading, 12.0)
                        .padding(.bottom, 12.0)
                        .ignoresSafeArea(edges: .bottom)
                }
            }
            .environment(\.stageStyle, style)
            .environment(\.stageSize, proxy.size)
            .sheet(isPresented: .constant(style == .sheet)) {
                panel()
                    .environment(harness)
                    .environment(layers)
                    .environment(\.stageStyle, .sheet)
                    .environment(\.stageSize, proxy.size)
                    .presentationDetents(detents, selection: $detent)
                    .presentationBackgroundInteraction(.enabled)
                    .presentationContentInteraction(.scrolls)
                    .interactiveDismissDisabled()
            }
        }
    }
}
