//
//  MapPopoverLayer.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2025/11/02.
//

import SwiftUI

struct MapPopoverLayer<Content: View>: View {

    @Binding var canvasSize: CGSize

    @Binding var selection: PopoverData?
    @Binding var popoverPosition: CGPoint?
    var content: (PopoverData) -> Content

    @State var currentItem: PopoverData?
    @State var dismissingItem: PopoverData?

    var body: some View {
        Group {
            if let currentItem, !currentItem.sourceRect.isNull {
                MapPopover(
                    canvasSize: $canvasSize,
                    popoverPosition: $popoverPosition,
                    sourceRect: currentItem.sourceRect,
                    isDismissing: false
                ) {
                    content(currentItem)
                }
                .id(currentItem.id)
            }
            if let dismissingItem, !dismissingItem.sourceRect.isNull {
                MapPopover(
                    canvasSize: $canvasSize,
                    popoverPosition: .constant(nil),
                    sourceRect: dismissingItem.sourceRect,
                    isDismissing: true
                ) {
                    content(dismissingItem)
                }
                .id("!\(dismissingItem.id)")
            }
        }
        .onChange(of: selection) { oldValue, newValue in
            if oldValue != nil, newValue == nil {
                dismiss()
            } else if let oldValue, let newValue, oldValue.id != newValue.id {
                dismissingItem = oldValue
                currentItem = newValue
                Task {
                    try? await Task.sleep(nanoseconds: 300000000)
                    dismissingItem = nil
                }
            } else if let newValue {
                currentItem = newValue
            } else {
                currentItem = nil
            }
        }
    }

    func dismiss() {
        if let current = currentItem {
            dismissingItem = current
            currentItem = nil
            selection = nil

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                dismissingItem = nil
            }
        }
    }
}
