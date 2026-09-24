import ORBiT
import PhotosUI
import SwiftUI

/// `MyView` for a guest.
///
/// The real one is built around a circle.ms profile and the active event: a nickname and
/// PID from the API, the participation sections, and the event cover art behind it all.
/// A guest has none of that, so what is left is the name they were given and a picture
/// they can set locally — enough that the members list has a face against it.
struct GuestMyView: View {

    @Environment(SharedBuysSession.self) var sharedBuys

    @State private var isSelectingProfilePicture: Bool = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var profilePictureState: Image?

    @AppStorage("My.ProfilePicture") var profilePicture: Data?

    var body: some View {
        List {
            Section {
                VStack(alignment: .center, spacing: 10.0) {
                    Menu {
                        Button("My.ProfilePicture.SelectFromPhotos", systemImage: "photo") {
                            isSelectingProfilePicture.toggle()
                        }
                        Button("My.ProfilePicture.Remove", systemImage: "trash", role: .destructive) {
                            profilePicture = nil
                            profilePictureState = nil
                        }
                    } label: {
                        Group {
                            if let profilePictureState {
                                profilePictureState.resizable()
                            } else {
                                Image(.profile1).resizable()
                            }
                        }
                        .scaledToFill()
                        .frame(width: 220.0, height: 220.0)
                        .clipShape(.circle)
                    }
                    Text(sharedBuys.nickname)
                        .font(.largeTitle)
                        .fontWeight(.black)
                        .padding(.top, 2.0)
                    Text("My.Guest.Subtitle")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity, alignment: .center)
                .listRowBackground(Color.clear)
            }
            if sharedBuys.isActive {
                Section {
                    ForEach(sharedBuys.members.sorted(by: { $0.value < $1.value }), id: \.key) { member in
                        HStack(spacing: 10.0) {
                            MemberInitial(
                                nickname: member.value,
                                isMine: member.key == sharedBuys.actorPID,
                                size: 30.0
                            )
                            Text(member.value)
                        }
                    }
                } header: {
                    Text("Buys.Shared.Members")
                }
            }
        }
        .listSectionSpacing(.compact)
        .navigationTitle("ViewTitle.My")
        .navigationBarTitleDisplayMode(.inline)
        .photosPicker(
            isPresented: $isSelectingProfilePicture,
            selection: $selectedPhotoItem,
            matching: .images
        )
        .task(id: selectedPhotoItem) {
            guard let selectedPhotoItem,
                  let data = try? await selectedPhotoItem.loadTransferable(type: Data.self)
            else { return }
            profilePicture = data
            if let image = UIImage(data: data) {
                profilePictureState = Image(uiImage: image)
            }
        }
        .task {
            if let profilePicture, let image = UIImage(data: profilePicture) {
                profilePictureState = Image(uiImage: image)
            }
        }
    }
}
