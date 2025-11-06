//
//  MapPopoverLayer.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2025/11/02.
//

import SwiftUI

struct MapPopoverLayer<Content: View>: View {

    @Binding var sourceRect: CGRect
    @Binding var selection: WebCatalogIDSet?
    @Binding var canvasSize: CGSize
    var content: (WebCatalogIDSet, Bool) -> Content

    @State var currentRect: CGRect = .null
    @State var currentItem: WebCatalogIDSet?

    @State var dismissingRect: CGRect = .null
    @State var dismissingItem: WebCatalogIDSet?

    var body: some View {
        ZStack {
            Color.clear
            if let currentItem, !currentRect.isNull {
                MapPopover(
                    sourceRect: currentRect,
                    canvasSize: canvasSize,
                    isDismissing: false
                ) {
                    content(currentItem, false)
                }
                .id(currentItem.id)
            }

            if let dismissingItem, !dismissingRect.isNull {
                MapPopover(
                    sourceRect: dismissingRect,
                    canvasSize: canvasSize,
                    isDismissing: true
                ) {
                    content(dismissingItem, true)
                }
                .id("!\(dismissingItem.id)")
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onChange(of: sourceRect) { oldValue, newValue in
            currentRect = newValue
            dismissingRect = oldValue
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
