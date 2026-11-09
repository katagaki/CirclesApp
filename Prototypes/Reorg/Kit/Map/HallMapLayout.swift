import SwiftUI

struct HallMapLayout {

    static let slotsPerBlock = 16

    let hall: Hall
    let hallRect: CGRect

    init(hall: Hall, size: CGSize) {
        self.hall = hall
        let inset = CGRect(origin: .zero, size: size).insetBy(dx: 16.0, dy: 16.0)
        let aspect: CGFloat = 1.25
        var width = inset.width
        var height = width * aspect
        if height > inset.height {
            height = inset.height
            width = height / aspect
        }
        hallRect = CGRect(x: inset.midX - width / 2.0, y: inset.midY - height / 2.0, width: max(width, 1.0), height: max(height, 1.0))
    }

    var contentRect: CGRect {
        hallRect.insetBy(dx: hallRect.width * 0.06, dy: hallRect.height * 0.08)
    }

    func columnRect(_ blockIndex: Int) -> CGRect {
        let count = CGFloat(hall.blocks.count)
        let pitch = contentRect.width / count
        let width = pitch * 0.42
        let x = contentRect.minX + pitch * CGFloat(blockIndex) + (pitch - width) / 2.0
        return CGRect(x: x, y: contentRect.minY, width: width, height: contentRect.height * 0.9)
    }

    func slotRect(block: Int, slot: Int) -> CGRect {
        let column = columnRect(block)
        let pitch = column.height / CGFloat(Self.slotsPerBlock)
        let gap: CGFloat = slot >= Self.slotsPerBlock / 2 ? pitch * 0.6 : 0.0
        return CGRect(x: column.minX, y: column.minY + pitch * CGFloat(slot) + gap, width: column.width, height: pitch * 0.82)
    }

    func point(for circle: MockCircle) -> CGPoint {
        let rect = slotRect(block: circle.blockIndex, slot: circle.slotIndex)
        return CGPoint(x: rect.midX, y: rect.midY)
    }

    func aislePoint(for circle: MockCircle) -> CGPoint {
        let column = columnRect(circle.blockIndex)
        let rect = slotRect(block: circle.blockIndex, slot: circle.slotIndex)
        return CGPoint(x: column.maxX + (contentRect.width / CGFloat(hall.blocks.count) - column.width) / 2.0, y: rect.midY)
    }

    var entrance: CGPoint {
        CGPoint(x: hallRect.midX, y: hallRect.maxY - 4.0)
    }
}
