#if os(iOS) && !targetEnvironment(macCatalyst)
import Foundation
import UIKit

/// Item photos for the Shared Buys Live Activity. The widget cannot read the app's cache,
/// and Live Activities drop large images, so the app leaves a small copy in the app group.
public enum SharedBuysActivityImageStore {

    static var directory: URL? {
        FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: "group.com.tsubuzaki.CiRCLES")?
            .appending(path: "SharedBuysImages", directoryHint: .isDirectory)
    }

    static func fileURL(for key: String) -> URL? {
        directory?.appending(path: "\(key).jpg")
    }

    static func save(_ image: Data, for key: String) -> Bool {
        if contains(key) { return true }
        guard let directory, let url = fileURL(for: key),
              let thumbnail = thumbnail(of: image) else { return false }
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return (try? thumbnail.write(to: url, options: .atomic)) != nil
    }

    static func contains(_ key: String) -> Bool {
        guard let url = fileURL(for: key) else { return false }
        return FileManager.default.fileExists(atPath: url.path())
    }

    public static func image(for key: String) -> UIImage? {
        guard let url = fileURL(for: key) else { return nil }
        return UIImage(contentsOfFile: url.path())
    }

    static func removeAll() {
        guard let directory else { return }
        try? FileManager.default.removeItem(at: directory)
    }

    private static func thumbnail(of data: Data) -> Data? {
        guard let image = UIImage(data: data) else { return nil }
        let largestSide = max(image.size.width, image.size.height)
        guard largestSide > 0.0 else { return nil }
        let scale = min(1.0, 200.0 / largestSide)
        let size = CGSize(width: (image.size.width * scale).rounded(), height: (image.size.height * scale).rounded())
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1.0
        return UIGraphicsImageRenderer(size: size, format: format)
            .image { _ in image.draw(in: CGRect(origin: .zero, size: size)) }
            .jpegData(compressionQuality: 0.8)
    }
}
#endif
