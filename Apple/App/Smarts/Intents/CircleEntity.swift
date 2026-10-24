import AppIntents
import Foundation

/// A circle in the catalog of the event the app last had open.
///
/// The identifier carries the event number as well as the circle's, since circle IDs are
/// only unique within one event's catalog: `"107-1234"`.
struct CircleEntity: AppEntity {

    static let typeDisplayRepresentation: TypeDisplayRepresentation = "Intents.Circle"
    static let defaultQuery = CircleEntityQuery()

    let id: String
    let name: String
    let penName: String
    let spaceName: String

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(
            title: "\(name)",
            subtitle: penName.isEmpty ? "\(spaceName)" : "\(spaceName)  \(penName)",
            image: .init(systemName: "person.2.fill")
        )
    }

    init(_ summary: CircleSummary, eventNumber: Int) {
        self.id = Self.identifier(eventNumber: eventNumber, circleID: summary.id)
        self.name = summary.name
        self.penName = summary.penName
        self.spaceName = summary.spaceName
    }

    static func identifier(eventNumber: Int, circleID: Int) -> String {
        "\(eventNumber)-\(circleID)"
    }

    static func parse(_ identifier: String) -> (eventNumber: Int, circleID: Int)? {
        let parts = identifier.split(separator: "-")
        guard parts.count == 2, let eventNumber = Int(parts[0]), let circleID = Int(parts[1]) else {
            return nil
        }
        return (eventNumber, circleID)
    }

    /// The entities for circles found by `find`, against the current event's catalog.
    static func entities(
        limit: Int = 20,
        _ find: (DataFetcher) async -> [Int]
    ) async -> [CircleEntity] {
        guard let catalog = CircleFinder.catalog() else { return [] }
        let fetcher = DataFetcher(database: catalog.connection)
        let identifiers = Array(await find(fetcher).prefix(limit))
        return await fetcher.circleSummaries(identifiers).map {
            CircleEntity($0, eventNumber: catalog.eventNumber)
        }
    }
}

struct CircleEntityQuery: EntityStringQuery {

    func entities(for identifiers: [CircleEntity.ID]) async throws -> [CircleEntity] {
        guard let eventNumber = CircleFinder.catalog()?.eventNumber else { return [] }
        let circleIDs = identifiers.compactMap(CircleEntity.parse)
            .filter { $0.eventNumber == eventNumber }
            .map(\.circleID)
        return await CircleEntity.entities(limit: circleIDs.count) { _ in circleIDs }
    }

    func entities(matching string: String) async throws -> [CircleEntity] {
        await CircleEntity.entities { fetcher in
            let placed = await fetcher.circles(mentionedIn: string)
            return placed.isEmpty ? await fetcher.circles(containing: string) : placed
        }
    }

    func suggestedEntities() async throws -> [CircleEntity] {
        []
    }
}
