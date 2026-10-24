import Foundation
import SQLite
import Vision
import AXiS

/// Turns what someone saw — a post, a screenshot, a line of text — into circles.
enum CircleFinder {

    // MARK: Text

    static func circles(mentionedIn text: String, using fetcher: DataFetcher) async -> [Int] {
        let identifiers = await fetcher.circles(mentionedIn: text)
        if !identifiers.isEmpty {
            return identifiers
        }
        // Sharing a post from X hands over its link and nothing else; the text has to be
        // fetched before there is anything to read.
        guard let postURL = postURL(in: text), let postText = await postText(for: postURL) else {
            return []
        }
        return await fetcher.circles(mentionedIn: postText)
    }

    // MARK: Images

    static func text(in imageData: Data) async -> String? {
        await text { try await $0.perform(on: imageData) }
    }

    static func text(in image: CGImage) async -> String? {
        await text { try await $0.perform(on: image) }
    }

    private static func text(
        _ perform: (RecognizeTextRequest) async throws -> [RecognizedTextObservation]
    ) async -> String? {
        var request = RecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.recognitionLanguages = [Locale.Language(identifier: "ja-JP"), Locale.Language(identifier: "en-US")]
        // Correction rewrites block letters and space numbers into words.
        request.usesLanguageCorrection = false
        guard let observations = try? await perform(request) else { return nil }
        let lines = observations.compactMap { $0.topCandidates(1).first?.string }
        return lines.isEmpty ? nil : lines.joined(separator: "\n")
    }

    // MARK: Catalog

    /// A connection to the catalog of the event the app last had open, for callers that run
    /// outside the app's views (App Intents and Visual Intelligence) and so have no `Database`.
    static func catalog() -> (connection: Connection, eventNumber: Int)? {
        let key = "Events.Active.Number"
        let eventNumber = UserDefaults.standard.object(forKey: key) as? Int
            ?? UserDefaults(suiteName: "group.com.tsubuzaki.CiRCLES")?.object(forKey: key) as? Int
        guard let eventNumber, eventNumber > 0 else { return nil }
        let fileName = "webcatalog\(eventNumber).db"
        let candidates = [
            FileManager.default.containerURL(
                forSecurityApplicationGroupIdentifier: "group.com.tsubuzaki.CiRCLES"
            )?.appending(path: fileName),
            FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appending(path: fileName)
        ].compactMap { $0 }
        guard let url = candidates.first(where: {
            FileManager.default.fileExists(atPath: $0.path(percentEncoded: false))
        }) else { return nil }
        guard let connection = try? Connection(url.path(percentEncoded: false), readonly: true) else {
            return nil
        }
        return (connection, eventNumber)
    }

    // MARK: X Posts

    static func postURL(in text: String) -> URL? {
        let pattern = #/https?://(?:www\.|mobile\.)?(?:x|twitter)\.com/[A-Za-z0-9_]+/status/\d+/#
        guard let match = text.firstMatch(of: pattern) else { return nil }
        return URL(string: String(match.output))
    }

    /// The text of a public post, from X's oEmbed endpoint, which needs no account.
    static func postText(for postURL: URL) async -> String? {
        var components = URLComponents(string: "https://publish.twitter.com/oembed")
        components?.queryItems = [
            URLQueryItem(name: "url", value: postURL.absoluteString),
            URLQueryItem(name: "omit_script", value: "true"),
            URLQueryItem(name: "lang", value: "ja")
        ]
        guard let url = components?.url,
              let (data, response) = try? await URLSession.shared.data(from: url),
              (response as? HTTPURLResponse)?.statusCode == 200,
              let embed = try? JSONDecoder().decode(PostEmbed.self, from: data) else { return nil }
        // The post is the first paragraph of the embed; the rest is the byline and date.
        let paragraph = embed.html.firstMatch(of: #/<p[^>]*>(?<body>.*?)</p>/#.dotMatchesNewlines())
            .map { String($0.output.body) } ?? embed.html
        return plainText(fromHTML: paragraph)
    }

    private struct PostEmbed: Decodable {
        let html: String
    }

    private static func plainText(fromHTML html: String) -> String {
        html
            .replacing(#/<br\s*/?>/#.ignoresCase(), with: "\n")
            .replacing(#/<[^>]+>/#, with: "")
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&#39;", with: "'")
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
            .replacingOccurrences(of: "&nbsp;", with: " ")
            .replacingOccurrences(of: "&amp;", with: "&")
    }
}
