#if os(iOS) && !targetEnvironment(macCatalyst)
import Foundation
import UIKit

/// Circle cuts for the route Live Activity. The widget cannot open the catalog, so the app
/// leaves a small copy of each stop's cut in the app group for it to read.
public enum RouteCutStore {

    static var directory: URL? {
        FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: "group.com.tsubuzaki.CiRCLES")?
            .appending(path: "RouteCuts", directoryHint: .isDirectory)
    }

    static func fileURL(for circleID: Int) -> URL? {
        directory?.appending(path: "\(circleID).jpg")
    }

    public static func save(_ data: Data, for circleID: Int) {
        guard let directory, let url = fileURL(for: circleID) else { return }
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try? data.write(to: url, options: .atomic)
    }

    public static func contains(_ circleID: Int) -> Bool {
        guard let url = fileURL(for: circleID) else { return false }
        return FileManager.default.fileExists(atPath: url.path())
    }

    public static func image(for circleID: Int) -> UIImage? {
        guard let url = fileURL(for: circleID) else { return nil }
        return UIImage(contentsOfFile: url.path())
    }

    public static func removeAll() {
        guard let directory else { return }
        try? FileManager.default.removeItem(at: directory)
    }
}
#endif
