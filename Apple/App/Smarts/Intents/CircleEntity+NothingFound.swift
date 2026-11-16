import Foundation
import UIKit

extension CircleEntity {

    /// Why Visual Intelligence found no circles. It shows a result saying so, as an empty list
    /// would leave nothing on screen at all.
    enum NothingFound: String, CaseIterable, Sendable {
        case unreadableImage
        case noCatalog
        case noText
        case noCircles

        var message: String {
            switch self {
            case .unreadableImage: String(localized: "Intents.NothingFound.UnreadableImage")
            case .noCatalog: String(localized: "Intents.NothingFound.NoCatalog")
            case .noText: String(localized: "Intents.NothingFound.NoText")
            case .noCircles: String(localized: "Intents.NothingFound.NoCircles")
            }
        }

        var systemImage: String {
            switch self {
            case .unreadableImage: "exclamationmark.triangle"
            case .noCatalog: "arrow.down.circle"
            case .noText: "text.viewfinder"
            case .noCircles: "magnifyingglass"
            }
        }
    }

    private static let nothingFoundPrefix = "none-"

    init(nothingFound reason: NothingFound) {
        self.id = Self.nothingFoundPrefix + reason.rawValue
        self.name = String(localized: "Intents.NothingFound")
        self.penName = ""
        self.spaceName = reason.message
        self.cut = Self.nothingFoundImage(systemName: reason.systemImage, message: reason.message)
        self.nothingFound = reason
    }

    init?(nothingFoundIdentifier identifier: String) {
        guard identifier.hasPrefix(Self.nothingFoundPrefix),
              let reason = NothingFound(rawValue: String(identifier.dropFirst(Self.nothingFoundPrefix.count))) else {
            return nil
        }
        self.init(nothingFound: reason)
    }

    private static func nothingFoundImage(systemName: String, message: String) -> Data? {
        let size = CGSize(width: 280.0, height: 280.0)
        return UIGraphicsImageRenderer(size: size).pngData { context in
            UIColor.secondarySystemBackground.setFill()
            context.fill(CGRect(origin: .zero, size: size))

            let symbolConfiguration = UIImage.SymbolConfiguration(pointSize: 56.0, weight: .medium)
                .applying(UIImage.SymbolConfiguration(hierarchicalColor: .secondaryLabel))
            if let symbol = UIImage(systemName: systemName, withConfiguration: symbolConfiguration) {
                symbol.draw(in: CGRect(
                    x: (size.width - symbol.size.width) / 2,
                    y: 76.0 - symbol.size.height / 2,
                    width: symbol.size.width,
                    height: symbol.size.height
                ))
            }

            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = .center
            paragraphStyle.lineBreakMode = .byWordWrapping
            (message as NSString).draw(
                in: CGRect(x: 20.0, y: 140.0, width: size.width - 40.0, height: 120.0),
                withAttributes: [
                    .font: UIFont.systemFont(ofSize: 17.0, weight: .medium),
                    .foregroundColor: UIColor.secondaryLabel,
                    .paragraphStyle: paragraphStyle
                ]
            )
        }
    }
}
