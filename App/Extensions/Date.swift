import Foundation

extension Date: @retroactive Identifiable {
    public var id: String {
        self.ISO8601Format()
    }
}
