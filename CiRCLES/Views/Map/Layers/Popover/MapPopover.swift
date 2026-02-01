//
//  MapPopover.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2025/11/02.
//

import SwiftUI

struct MapPopover<Content: View>: View {

    @Environment(Mapper.self) var mapper

    let edgePadding: CGFloat = 16.0

    var zoomScale: CGFloat

    var sourceRect: CGRect
    var isDismissing: Bool
    var content: () -> Content

    @State var animationProgress: CGFloat = 0

    var body: some View {
        content()
            .padding(16.0)
            .frame(width: mapper.popoverWidth, height: mapper.popoverHeight)
            .adaptiveGlass(.regular)
            .scaleEffect((0.3 + (0.7 * animationProgress)) / zoomScale)
            .opacity(animationProgress)
            .position(animatedPosition())
            .onAppear {
                if isDismissing {
                    animationProgress = 1
                    withAnimation(.smooth.speed(2.5)) {
                        animationProgress = 0
                    }
                } else {
                    withAnimation(.smooth.speed(2.5)) {
                        animationProgress = 1
                    }
                    mapper.popoverPosition = calculatePopoverPosition()
                }
            }
    }

    func animatedPosition() -> CGPoint {
        let finalPosition = calculatePopoverPosition()
        let startPosition = CGPoint(x: sourceRect.midX, y: sourceRect.midY)

        return CGPoint(
            x: startPosition.x + (finalPosition.x - startPosition.x) * animationProgress,
            y: startPosition.y + (finalPosition.y - startPosition.y) * animationProgress
        )
    }

    // swiftlint:disable function_body_length
    func calculatePopoverPosition() -> CGPoint {
        let canvasSize = mapper.canvasSize
        let popoverWidth = mapper.popoverWidth / zoomScale
        let popoverHeight = mapper.popoverHeight / zoomScale
        let popoverDistance: CGFloat = mapper.popoverDistance / zoomScale
        let edgePadding = mapper.popoverEdgePadding / zoomScale

        let effectiveHeight = max(popoverHeight, 150)
        let itemCenterX = sourceRect.midX
        let itemCenterY = sourceRect.midY
        let itemHalfWidth = sourceRect.width / 2
        let itemHalfHeight = sourceRect.height / 2
        let minOffsetX = itemHalfWidth + popoverDistance + (popoverWidth / 2)
        let minOffsetY = itemHalfHeight + popoverDistance + (effectiveHeight / 2)

        let spaceRight = canvasSize.width - edgePadding - (itemCenterX + minOffsetX + popoverWidth / 2)
        let spaceLeft = (itemCenterX - minOffsetX - popoverWidth / 2) - edgePadding
        let spaceBottom = canvasSize.height - edgePadding - (itemCenterY + minOffsetY + effectiveHeight / 2)
        let spaceTop = (itemCenterY - minOffsetY - effectiveHeight / 2) - edgePadding

        var positionX: CGFloat
        var positionY: CGFloat

        let canFitRight = spaceRight >= 0
        let canFitLeft = spaceLeft >= 0
        let canFitBelow = spaceBottom >= 0
        let canFitAbove = spaceTop >= 0

        let nearTopEdge = itemCenterY < canvasSize.height * 0.3
        let nearBottomEdge = itemCenterY > canvasSize.height * 0.7

        if nearTopEdge && canFitBelow {
            positionX = itemCenterX
            positionY = itemCenterY + minOffsetY
        } else if nearBottomEdge && canFitAbove {
            positionX = itemCenterX
            positionY = itemCenterY - minOffsetY
        } else if canFitRight {
            positionX = itemCenterX + minOffsetX
            positionY = itemCenterY

            if positionY + effectiveHeight / 2 > canvasSize.height - edgePadding {
                positionY = canvasSize.height - edgePadding - effectiveHeight / 2
            } else if positionY - effectiveHeight / 2 < edgePadding {
                positionY = edgePadding + effectiveHeight / 2
            }
        } else if canFitLeft {
            positionX = itemCenterX - minOffsetX
            positionY = itemCenterY

            if positionY + effectiveHeight / 2 > canvasSize.height - edgePadding {
                positionY = canvasSize.height - edgePadding - effectiveHeight / 2
            } else if positionY - effectiveHeight / 2 < edgePadding {
                positionY = edgePadding + effectiveHeight / 2
            }
        } else if canFitBelow {
            positionX = itemCenterX
            positionY = itemCenterY + minOffsetY
        } else if canFitAbove {
            positionX = itemCenterX
            positionY = itemCenterY - minOffsetY
        } else {
            positionX = itemCenterX + minOffsetX
            positionY = itemCenterY
        }

        positionX = max(
            edgePadding + popoverWidth / 2,
            min(canvasSize.width - edgePadding - popoverWidth / 2, positionX)
        )
        positionY = max(
            edgePadding + effectiveHeight / 2,
            min(canvasSize.height - edgePadding - effectiveHeight / 2, positionY)
        )

        return CGPoint(x: positionX, y: positionY)
    }
    // swiftlint:enable function_body_length
}
