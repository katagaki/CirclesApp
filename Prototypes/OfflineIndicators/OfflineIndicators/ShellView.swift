import SwiftUI

struct ShellView: View {
    @Environment(Harness.self) private var harness

    var body: some View {
        @Bindable var harness = harness
        NavigationStack {
            ZStack(alignment: .top) {
                MapMock()
                    .ignoresSafeArea()
                IndicatorLayer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("My", systemImage: "person.crop.circle") {}
                }
                ToolbarItem(placement: .principal) {
                    ControlMock()
                }
                if harness.variant == .toolbar && harness.isOffline {
                    ToolbarItem(placement: .topBarTrailing) {
                        ToolbarIndicator()
                    }
                    ToolbarSpacer(.fixed, placement: .topBarTrailing)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    MoreMenuMock()
                }
            }
        }
        .overlay {
            if harness.showsGradient {
                ZStack(alignment: .top) {
                    Color.clear
                    LinearGradient(
                        colors: [.pink.opacity(0.3), .clear],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 24.0)
                    .frame(maxWidth: .infinity)
                    .ignoresSafeArea()
                }
                .allowsHitTesting(false)
            }
        }
        .sheet(isPresented: .constant(true)) {
            PanelView()
                .presentationBackgroundInteraction(.enabled)
                .presentationDetents([.height(88), .height(360), .large], selection: $harness.detent)
                .presentationContentInteraction(.scrolls)
                .interactiveDismissDisabled()
                .environment(harness)
        }
    }
}

struct ControlMock: View {
    var body: some View {
        HStack {
            Text("1日目")
                .font(.subheadline.bold())
                .padding(.leading, 12.0)
            Spacer()
            Text("東456")
                .font(.subheadline.bold())
                .foregroundStyle(.white)
                .padding(.horizontal, 12.0)
                .padding(.vertical, 6.0)
                .background(.red, in: .capsule)
        }
        .frame(minWidth: 100.0, maxWidth: 280.0)
        .padding(6.0)
        .glassEffect(.regular.interactive())
    }
}

struct MoreMenuMock: View {
    @Environment(Harness.self) private var harness

    var body: some View {
        Menu("More", systemImage: "ellipsis") {
            Section(harness.localized("Account", "アカウント")) {
                if harness.status == .manual {
                    Button(harness.actionTitle) { harness.performAction() }
                } else {
                    Button(harness.localized("Switch to Offline Mode", "オフラインモードに切り替え")) {
                        harness.alert = .enter
                    }
                }
            }
        }
    }
}

struct MapMock: View {
    var body: some View {
        Canvas { context, size in
            context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(Color(white: 0.96)))
            let cell: CGFloat = 13.0
            var row = 0
            var y: CGFloat = 8.0
            while y < size.height {
                var column = 0
                var x: CGFloat = 10.0
                while x < size.width {
                    if column % 9 != 8 {
                        let isFavorite = (row * 31 + column * 17) % 23 == 0
                        let rect = CGRect(x: x, y: y, width: cell - 1.0, height: cell - 1.0)
                        context.fill(
                            Path(rect),
                            with: .color(isFavorite ? .pink.opacity(0.75) : Color(white: 0.84))
                        )
                    }
                    x += cell
                    column += 1
                }
                y += row % 2 == 1 ? cell + 16.0 : cell
                row += 1
            }
        }
    }
}
