import SwiftUI

struct ToolbeltToolScreen: View {

    let tool: ToolbeltTool
    @Binding var path: [Feature]
    let close: () -> Void

    var body: some View {
        NavigationStack(path: $path) {
            Group {
                switch tool {
                case .route: RouteView()
                case .sharedBuys: SharedBuysView()
                case .me: ToolbeltMeView()
                }
            }
            .navigationTitle(tool.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(role: .close, action: close)
                }
            }
            .featureDestinations()
        }
    }
}
