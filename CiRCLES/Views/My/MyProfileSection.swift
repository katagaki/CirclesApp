//
//  MyProfileSection.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2024/09/07.
//

import PhotosUI
import SwiftUI

struct MyProfileSection: View {

    @Binding var userInfo: UserInfo.Response?

    @State var isShowingUserPID: Bool = false
    @State var isSelectingProfilePicture: Bool = false
    @State var selectedPhotoItem: PhotosPickerItem?

    @AppStorage("My.ProfilePicture") var profilePicture: Data?

    @State var profilePictureState: Image?

    var body: some View {
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
                            profilePictureState
                                .resizable()
                        } else {
                            Image(.profile1)
                                .resizable()
                        }
                    }
                    .scaledToFill()
                    .frame(width: 110.0, height: 110.0)
                    .clipShape(.circle)
                }
                VStack(alignment: .center) {
                    Group {
                        if let userInfo {
                            Text(userInfo.nickname)
                        } else {
                            Text(verbatim: "-")
                        }
                    }
                    .fontWeight(.bold)
                    .font(.title3)
                    .onLongPressGesture {
                        isShowingUserPID.toggle()
                    }
                    if isShowingUserPID {
                        Text("PID " + String(userInfo?.pid ?? 0))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.top, 2.0)
                Link(destination: URL(string: "https://myportal.circle.ms/")!) {
                    Text("Profile.Edit")
                        .font(.caption)
                        .underline()
                        .foregroundStyle(.accent)
                }
            }
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity, alignment: .center)
            .alignmentGuide(.listRowSeparatorLeading) { _ in
                0.0
            }
        }
        .listRowBackground(Color.clear)
        .onAppear {
            if let profilePicture,
               let profilePictureUIImage = UIImage(data: profilePicture) {
                profilePictureState = Image(uiImage: profilePictureUIImage)
            }
        }
        .photosPicker(isPresented: $isSelectingProfilePicture, selection: $selectedPhotoItem,
                      matching: .images, photoLibrary: .shared())
        .onChange(of: selectedPhotoItem) { _, newPhotoItem in
            Task {
                if let newPhotoItem,
                   let photoData = try? await newPhotoItem.loadTransferable(type: Data.self),
                   let profilePictureUIImage = UIImage(data: photoData) {
                    profilePicture = photoData
                    profilePictureState = Image(uiImage: profilePictureUIImage)
                }
                selectedPhotoItem = nil
            }
        }
    }
}
