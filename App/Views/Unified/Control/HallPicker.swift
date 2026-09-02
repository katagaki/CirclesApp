import SwiftData
import SwiftUI
import AXiS

struct HallPicker: View {
    @Environment(UserSelections.self) var selections
    @Environment(Database.self) var database
    @State var isMinimapPresented: Bool = false
    @State var buttonFrame: CGRect = .zero

    var body: some View {
        Button {
            isMinimapPresented = true
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
                    .onAppear { buttonFrame = proxy.frame(in: .global) }
                    .onChange(of: proxy.frame(in: .global)) { _, newValue in
                        buttonFrame = newValue
                    }
            }
        }
        .fullScreenCover(isPresented: $isMinimapPresented) {
            HallMinimapMenu(anchor: $buttonFrame) { map in
                selections.map = map
            }
            .presentationBackground(.clear)
        }
        .transaction { transaction in
            transaction.disablesAnimations = true
        }
    }
}

struct HallMinimapMenu: View {
    @Environment(UserSelections.self) var selections
    @Environment(Database.self) var database
    @Environment(\.dismiss) var dismiss

    @Binding var anchor: CGRect
    let onSelect: (ComiketMap) -> Void

    let minimapWidth: CGFloat = 268.0
    let padding: CGFloat = 16.0
    let edgePadding: CGFloat = 8.0

    @State var animationProgress: CGFloat = 0.0

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
                    onSelect(map)
                    close()
                }
                .padding(padding)
                .frame(width: menuWidth)
                .glassEffect(.regular, in: .rect(cornerRadius: 20.0))
                .scaleEffect(0.9 + 0.1 * animationProgress, anchor: .top)
                .opacity(animationProgress)
                .offset(x: menuOriginX(in: container) - container.minX,
                        y: anchor.maxY + edgePadding - container.minY)
            }
        }
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.smooth(duration: 0.2)) {
                animationProgress = 1.0
            }
        }
    }

    func menuOriginX(in container: CGRect) -> CGFloat {
        let preferred = anchor.midX - menuWidth / 2.0
        let minimumX = container.minX + edgePadding
        let maximumX = container.maxX - menuWidth - edgePadding
        return min(max(preferred, minimumX), max(minimumX, maximumX))
    }

    func close() {
        withAnimation(.smooth(duration: 0.15)) {
            animationProgress = 0.0
        } completion: {
            dismiss()
        }
    }
}
