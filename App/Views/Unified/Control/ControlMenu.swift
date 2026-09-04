//
//  ControlMenu.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2026/09/04.
//

import SwiftUI

enum ControlMenuMetrics {
    static let cornerRadius: CGFloat = 32.0
    static let padding: CGFloat = 16.0
    // Concentric with the menu's own corner.
    static let contentCornerRadius: CGFloat = cornerRadius - padding
}

struct ControlMenu<Content: View>: View {
    @Environment(Unifier.self) var unifier

    let contentWidth: CGFloat
    let isContentEdgeToEdge: Bool
    let content: (@escaping () -> Void) -> Content

    let padding: CGFloat = ControlMenuMetrics.padding
    let edgePadding: CGFloat = 8.0
    // Matches the corner of a native iOS 26 popover.
    let cornerRadius: CGFloat = ControlMenuMetrics.cornerRadius

    @State var animationProgress: CGFloat = 0.0
    @State var menuHeight: CGFloat = 0.0

    init(
        contentWidth: CGFloat,
        isContentEdgeToEdge: Bool = false,
        @ViewBuilder content: @escaping (@escaping () -> Void) -> Content
    ) {
        self.contentWidth = contentWidth
        self.isContentEdgeToEdge = isContentEdgeToEdge
        self.content = content
    }

    var anchor: CGRect {
        unifier.controlFrame
    }

    var menuWidth: CGFloat {
        contentWidth + padding * 2.0
    }

    // Unfurls downwards out of the toolbar instead of resizing the content itself.
    var revealHeight: CGFloat {
        let collapsedHeight = min(anchor.height, menuHeight)
        return collapsedHeight + (menuHeight - collapsedHeight) * animationProgress
    }

    var body: some View {
        GeometryReader { proxy in
            let container = proxy.frame(in: .global)
            ZStack(alignment: .topLeading) {
                Color.clear
                    .contentShape(.rect)
                    .onTapGesture { close() }
                content(close)
                    .padding(.vertical, padding)
                    .padding(.horizontal, isContentEdgeToEdge ? 0.0 : padding)
                    .frame(width: menuWidth)
                    .glassEffect(.regular, in: .rect(cornerRadius: cornerRadius, style: .continuous))
                    .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { menuHeight = $0 }
                    .mask(alignment: .top) {
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
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

    func menuOriginX(in container: CGRect) -> CGFloat {
        let preferred = container.midX - menuWidth / 2.0
        let minimumX = container.minX + edgePadding
        let maximumX = container.maxX - menuWidth - edgePadding
        return min(max(preferred, minimumX), max(minimumX, maximumX))
    }

    func close() {
        withAnimation(.smooth(duration: 0.25)) {
            animationProgress = 0.0
            unifier.presentedControlMenu = nil
        }
    }
}
