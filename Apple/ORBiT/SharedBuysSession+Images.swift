import Foundation

/// A photo that has not reached the relay yet. Failed sends keep their bytes for a retry.
public struct SharedBuyImageSend: Sendable {
    public let image: Data
    public var isFailed: Bool
}

enum SharedBuysImageCache {

    private static var directory: URL? {
        guard let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
        else { return nil }
        let directory = caches.appending(path: "shared-buys-images")
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    static func load(_ imageID: String) -> Data? {
        guard let url = directory?.appending(path: imageID) else { return nil }
        return try? Data(contentsOf: url)
    }

    static func save(_ image: Data, as imageID: String) {
        guard let url = directory?.appending(path: imageID) else { return }
        try? image.write(to: url, options: .atomic)
    }
}

@MainActor
public extension SharedBuysSession {

    /// The largest encoded photo. Sealing adds 28 bytes, which stays under the relay's 1 MiB.
    static var maxImageBytes: Int { 1_000_000 }

    private static var imageSealOverhead: Int {
        SharedBuysCrypto.nonceLength + SharedBuysCrypto.tagLength
    }

    /// The photo for an item, from the cache. Reads `imageRevision` so a fetch redraws rows.
    func image(for item: SharedBuyItem) -> Data? {
        _ = imageRevision
        if let pending = imageSends[item.id] { return pending.image }
        return item.imageID.flatMap(SharedBuysImageCache.load)
    }

    /// Sends a WebP photo for an item. The item itself is already synced; only this waits.
    func attachImage(_ image: Data, to itemID: String, circleID: Int) {
        guard image.count <= Self.maxImageBytes, let sessionKey, let roomID else { return }
        imageSends[itemID] = SharedBuyImageSend(image: image, isFailed: false)
        let base = relayBaseURL
        Task {
            guard let imageID = await uploadImage(image, sessionKey: sessionKey, roomID: roomID, base: base) else {
                imageSends[itemID]?.isFailed = true
                note("image upload failed")
                return
            }
            guard self.sessionKey == sessionKey else { return }
            SharedBuysImageCache.save(image, as: imageID)
            recordImage(imageID, itemID: itemID, circleID: circleID)
            imageSends[itemID] = nil
            imageRevision += 1
        }
    }

    func retryImage(for item: SharedBuyItem) {
        guard let pending = imageSends[item.id] else { return }
        attachImage(pending.image, to: item.id, circleID: item.circleID)
    }

    /// Whether the relay has already dropped a photo this device never received.
    func isImageMissing(for item: SharedBuyItem) -> Bool {
        _ = imageRevision
        guard let imageID = item.imageID else { return false }
        return SharedBuysImageCache.load(imageID) == nil && !imageFetches.contains(imageID)
    }

    private func uploadImage(_ image: Data, sessionKey: Data, roomID: String, base: String) async -> String? {
        guard let imageID = await relay.requestImageSlot(size: image.count + Self.imageSealOverhead),
              let sealed = SharedBuysCrypto.sealImage(image, sessionKey: sessionKey, roomID: roomID, imageID: imageID),
              let url = Self.imageURL(base: base, roomID: roomID, imageID: imageID) else { return nil }
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        guard let (_, response) = try? await URLSession.shared.upload(for: request, from: sealed),
              (response as? HTTPURLResponse)?.statusCode == 204 else { return nil }
        return imageID
    }

    /// Fetches every photo in the room this device lacks, then tells the relay it may drop them.
    internal func fetchMissingImages() {
        guard let sessionKey, let roomID else { return }
        let base = relayBaseURL
        for imageID in Set(items.compactMap(\.imageID))
        where SharedBuysImageCache.load(imageID) == nil && imageFetches.insert(imageID).inserted {
            Task {
                defer {
                    imageFetches.remove(imageID)
                    imageRevision += 1
                }
                guard let url = Self.imageURL(base: base, roomID: roomID, imageID: imageID),
                      let (blob, response) = try? await URLSession.shared.data(from: url),
                      (response as? HTTPURLResponse)?.statusCode == 200,
                      let image = SharedBuysCrypto.openImage(
                          blob, sessionKey: sessionKey, roomID: roomID, imageID: imageID
                      ) else { return }
                SharedBuysImageCache.save(image, as: imageID)
                await relay.acknowledgeImage(imageID)
            }
        }
    }

    private static func imageURL(base: String, roomID: String, imageID: String) -> URL? {
        var http = base
        if http.hasPrefix("wss://") {
            http = "https://" + http.dropFirst("wss://".count)
        } else if http.hasPrefix("ws://") {
            http = "http://" + http.dropFirst("ws://".count)
        }
        return URL(string: "\(http)/r/\(roomID)/i/\(imageID)")
    }
}
