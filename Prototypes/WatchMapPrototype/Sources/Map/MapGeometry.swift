import CoreGraphics

enum MapGeometry {

    static let spaceSize: CGFloat = 40.0

    static func orderedIndex(suffix: Int, total: Int, layoutType: LayoutType) -> Int {
        guard total > 0 else { return 0 }
        let clamped = min(max(suffix, 0), total - 1)
        switch layoutType {
        case .aOnBottom, .aOnRight:
            return total - 1 - clamped
        default:
            return clamped
        }
    }

    static func rect(layout: SpaceLayout, index: Int, total: Int) -> CGRect {
        let count = CGFloat(max(total, 1))
        let offset = CGFloat(index)
        let baseX = layout.position.x
        let baseY = layout.position.y

        switch layout.layoutType {
        case .aOnLeft, .aOnRight, .unknown:
            let width = spaceSize / count
            return CGRect(x: baseX + offset * width, y: baseY, width: width, height: spaceSize)
        case .aOnTop, .aOnBottom:
            let height = spaceSize / count
            return CGRect(x: baseX, y: baseY + offset * height, width: spaceSize, height: height)
        }
    }

    static func rect(for circle: CatalogCircle, layout: SpaceLayout, occupants: Int) -> CGRect {
        let index = orderedIndex(
            suffix: circle.spaceNumberSuffix,
            total: occupants,
            layoutType: layout.layoutType
        )
        return rect(layout: layout, index: index, total: occupants)
    }
}
