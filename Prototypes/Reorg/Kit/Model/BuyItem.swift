import Foundation

struct BuyItem: Identifiable, Hashable {
    let id: Int
    let circleID: Int
    let title: String
    let price: Int
    var isBought: Bool
    var assignee: String?
}
