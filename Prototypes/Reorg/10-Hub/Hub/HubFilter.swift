import SwiftUI

enum HubFilter: Hashable {
    case all
    case favorites
    case color(FavoriteColor)
    case visited
}
