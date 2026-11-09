import SwiftUI

@Observable
final class LayersState {

    var enabled: Set<MapLayer> = []
    var focused: MapLayer?

    func tap(_ layer: MapLayer) {
        if focused == layer {
            enabled.remove(layer)
            focused = nil
        } else {
            enabled.insert(layer)
            focused = layer
        }
    }

    func hide(_ layer: MapLayer) {
        enabled.remove(layer)
        if focused == layer {
            focused = nil
        }
    }

    func show(_ layer: MapLayer) {
        enabled.insert(layer)
        focused = layer
    }
}
