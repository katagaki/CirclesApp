import SwiftUI

/// A shared Buys member's face: your own photo on your row, the generic figure otherwise.
///
/// Photos never leave the phone, so other members always draw as the figure, coloured by
/// their nickname and PID the same way on every member's phone.
struct MemberAvatar: View {

    @AppStorage("My.ProfilePicture") var profilePicture: Data?

    let nickname: String
    let pid: Int
    var isMine: Bool = false
    var isHighlighted: Bool = false
    var size: CGFloat = 26.0

    var body: some View {
        Group {
            if isMine, let profilePicture, let image = UIImage(data: profilePicture) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                GenericProfilePicture(name: nickname, userID: pid)
            }
        }
        .frame(width: size, height: size)
        .clipShape(.circle)
        .overlay {
            Circle().strokeBorder(isHighlighted ? Color.accentColor : .clear, lineWidth: 2.0)
        }
    }
}
