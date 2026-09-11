import SwiftUI

struct RootView: View {

    @Environment(Mesh.self) var mesh
    @State var isShowingHarness: Bool = false

    var body: some View {
        ZStack(alignment: .bottom) {
            MapBackdrop()
            VStack(spacing: 0.0) {
                HarnessBar(isShowingHarness: $isShowingHarness)
                if mesh.focused.isSessionActive {
                    LiveActivityPreview(device: mesh.focused)
                        .padding(.horizontal, 16.0)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
                Spacer()
            }
            PanelView()
                .ignoresSafeArea(edges: .bottom)
        }
        .animation(.smooth, value: mesh.focused.isSessionActive)
        .ignoresSafeArea(.keyboard)
        .environment(\.locale, Locale(identifier: mesh.isJapanese ? "ja" : "en"))
        .sheet(isPresented: $isShowingHarness) {
            HarnessSheet()
                .environment(\.locale, Locale(identifier: "en"))
        }
    }
}

struct MapBackdrop: View {

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
            GeometryReader { proxy in
                let columns = 7
                let rows = 9
                let width = proxy.size.width / CGFloat(columns)
                let height = proxy.size.height / CGFloat(rows)
                ForEach(0..<rows, id: \.self) { row in
                    ForEach(0..<columns, id: \.self) { column in
                        RoundedRectangle(cornerRadius: 2.0)
                            .fill(Color.secondary.opacity((row + column).isMultiple(of: 3) ? 0.10 : 0.05))
                            .frame(width: width - 6.0, height: height - 6.0)
                            .offset(x: CGFloat(column) * width + 3.0, y: CGFloat(row) * height + 3.0)
                    }
                }
            }
        }
        .ignoresSafeArea()
    }
}
