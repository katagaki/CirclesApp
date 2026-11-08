import SwiftUI

/// Where the visitor is standing, shown with their My Comiket photo.
struct MapRouteOriginPin: View {

    @AppStorage("My.ProfilePicture") var profilePicture: Data?

    let size: CGFloat

    var photo: Image {
        if let profilePicture, let image = UIImage(data: profilePicture) {
            return Image(uiImage: image)
        }
        return Image(.profile1)
    }

    var body: some View {
        photo
            .resizable()
            .scaledToFill()
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
