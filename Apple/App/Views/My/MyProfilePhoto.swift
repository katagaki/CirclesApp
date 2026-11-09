import SwiftUI

struct MyProfilePhoto: View {

    @AppStorage("My.ProfilePicture") var profilePicture: Data?
    @AppStorage("My.LastKnownNickname") var lastKnownNickname: String?
    @AppStorage(wrappedValue: 0, "My.LastKnownPID") var lastKnownPID: Int

    var body: some View {
        Group {
            if let profilePicture, let image = UIImage(data: profilePicture) {
                Image(uiImage: image)
                    .resizable()
            } else {
                GenericProfilePicture(name: lastKnownNickname ?? "", userID: lastKnownPID)
            }
        }
        .scaledToFill()
        .clipShape(.circle)
    }
}
