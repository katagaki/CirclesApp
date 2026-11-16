import AXiS
import Foundation
import SQLite
import UIKit

/// Small copies of circle cuts for results shown outside the app, such as in Visual Intelligence.
///
/// Only cuts already on the device are used: the web cut the app last downloaded, or else the
/// cut in the catalog's image database.
struct CircleCutThumbnails {

    private static let maximumSize = CGSize(width: 180.0, height: 256.0)

    private let imageDatabase: Connection?

    init(eventNumber: Int) {
        let path = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?
            .appending(path: "webcatalog\(eventNumber)Image1.db")
            .path(percentEncoded: false)
        if let path, FileManager.default.fileExists(atPath: path) {
            imageDatabase = try? Connection(path, readonly: true)
        } else {
            imageDatabase = nil
        }
    }

    func thumbnail(for circleID: Int) -> Data? {
        let data = webCut(for: circleID)
            ?? imageDatabase.flatMap { Database.readCircleImageData(from: $0, id: circleID) }
        guard let data, let image = UIImage(data: data) else { return nil }
        return Self.thumbnail(of: image)
    }

    private func webCut(for circleID: Int) -> Data? {
        // Where ImageCache keeps downloaded web cuts. An empty file marks a circle without one.
        guard let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?
            .appending(path: "ImageCache").appending(path: String(circleID)),
              let data = try? Data(contentsOf: url), !data.isEmpty else { return nil }
        return data
    }

    private static func thumbnail(of image: UIImage) -> Data? {
        let scale = min(1, maximumSize.width / image.size.width, maximumSize.height / image.size.height)
        let size = CGSize(width: (image.size.width * scale).rounded(), height: (image.size.height * scale).rounded())
        let format = UIGraphicsImageRendererFormat()
        format.scale = 2
        return UIGraphicsImageRenderer(size: size, format: format)
            .jpegData(withCompressionQuality: 0.85) { _ in
                image.draw(in: CGRect(origin: .zero, size: size))
            }
    }
}
