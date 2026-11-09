import SwiftUI

/// Where the visitor is standing, shown with their My Comiket photo.
struct MapRouteOriginPin: View {

    @AppStorage("My.ProfilePicture") var profilePicture: Data?
    @AppStorage("My.LastKnownNickname") var lastKnownNickname: String?
    @AppStorage(wrappedValue: 0, "My.LastKnownPID") var lastKnownPID: Int

    let size: CGFloat

    var body: some View {
        Group {
            if let profilePicture, let image = UIImage(data: profilePicture) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                GenericProfilePicture(name: lastKnownNickname ?? "", userID: lastKnownPID)
            }
        }
        .frame(width: size, height: size)
        .clipShape(.circle)
        .overlay {
            Circle()
                .strokeBorder(.white, lineWidth: size * 0.1)
        }
        .background {
            Circle()
                .fill(.white)
                .shadow(color: .black.opacity(0.3), radius: size * 0.08)
        }
    }
}
