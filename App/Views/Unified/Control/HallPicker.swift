import SwiftData
import SwiftUI
import AXiS

struct HallPicker: View {
    @Environment(UserSelections.self) var selections
    @Environment(Database.self) var database
    @Environment(Unifier.self) var unifier

    var body: some View {
        Button {
            withAnimation(.smooth(duration: 0.25)) {
                unifier.isHallMinimapPresenting = true
            }
        } label: {
            HStack(spacing: 10.0) {
                Image(systemName: "building")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 20.0)
                if let selectedMap = selections.map {
                    Text(selectedMap.name)
                } else {
                    Text("Shared.Placeholder.NoBlock")
                }
            }
            .padding(.vertical, 8.0)
            .padding(.horizontal, 16.0)
            .foregroundStyle(.white)
        }
        .buttonStyle(.plain)
        .background {
            GeometryReader { proxy in
                Color.clear
                    .onAppear { updateAnchor(proxy.frame(in: .global)) }
                    .onChange(of: proxy.frame(in: .global)) { _, newValue in
                        updateAnchor(newValue)
                    }
            }
        }
    }
}

extension HallPicker {
    // The menu's source moves with the transition, so keep the anchor frozen while it is open.
    func updateAnchor(_ frame: CGRect) {
        guard !unifier.isHallMinimapPresenting else { return }
        unifier.hallPickerFrame = frame
    }
}

struct HallMinimapMenu: View {
    @Environment(UserSelections.self) var selections
    @Environment(Database.self) var database
    @Environment(Unifier.self) var unifier

    let minimapWidth: CGFloat = 268.0
    let padding: CGFloat = 16.0
    let edgePadding: CGFloat = 8.0

    @State var animationProgress: CGFloat = 0.0
    @State var menuHeight: CGFloat = 0.0

    var anchor: CGRect {
        unifier.hallPickerFrame
    }

    var maps: [ComiketMap] {
        database.maps()
    }

    var menuWidth: CGFloat {
        minimapWidth + padding * 2.0
    }

    var body: some View {
        GeometryReader { proxy in
            let container = proxy.frame(in: .global)
            ZStack(alignment: .topLeading) {
                Color.clear
                    .contentShape(.rect)
                    .onTapGesture { close() }
                HallMinimap(maps: maps, selection: selections.map, width: minimapWidth) { map in
                    selections.map = map
                    close()
                }
                .padding(padding)
                .frame(width: menuWidth)
                .glassEffect(.regular, in: .rect(cornerRadius: 20.0))
                .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { menuHeight = $0 }
                .mask(alignment: .top) {
                    RoundedRectangle(cornerRadius: 20.0)
                        .frame(height: menuHeight > 0.0 ? revealHeight : nil)
                }
                .opacity(animationProgress)
                .offset(x: menuOriginX(in: container) - container.minX,
                        y: anchor.minY - edgePadding - container.minY)
            }
        }
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.smooth(duration: 0.25)) {
                animationProgress = 1.0
            }
        }
    }

    // Unfurls downwards out of the toolbar instead of resizing the minimap itself.
    var revealHeight: CGFloat {
        let collapsedHeight = min(anchor.height, menuHeight)
        return collapsedHeight + (menuHeight - collapsedHeight) * animationProgress
    }

    func menuOriginX(in container: CGRect) -> CGFloat {
        let preferred = container.midX - menuWidth / 2.0
        let minimumX = container.minX + edgePadding
        let maximumX = container.maxX - menuWidth - edgePadding
        return min(max(preferred, minimumX), max(minimumX, maximumX))
    }

    func close() {
        withAnimation(.smooth(duration: 0.25)) {
            animationProgress = 0.0
            unifier.isHallMinimapPresenting = false
        }
    }
}
