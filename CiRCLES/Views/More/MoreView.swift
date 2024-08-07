//
//  MoreView.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2024/07/15.
//

import Komponents
import SwiftUI

struct MoreView: View {
    @EnvironmentObject var navigationManager: NavigationManager
    @Environment(AuthManager.self) var authManager
    @Environment(UserManager.self) var user

    @State var isShowingUserPID: Bool = false

    var body: some View {
        NavigationStack(path: $navigationManager[.more]) {
            MoreList(repoName: "katagaki/CirclesApp", viewPath: ViewPath.moreAttributions) {
                Section {
                    HStack(alignment: .center, spacing: 16.0) {
                        Image("Profile.1")
                            .resizable()
                            .frame(width: 56.0, height: 56.0)
                            .clipShape(.circle)
                        VStack(alignment: .leading) {
                            Text(user.info?.nickname ?? NSLocalizedString("Profile.GenericUser",
                                                                                     comment: ""))
                                .fontWeight(.medium)
                                .font(.title3)
                            if isShowingUserPID {
                                Text("PID " + String(user.info?.pid ?? 0))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        Spacer()
                    }
                    .contentShape(.rect)
                    .onTapGesture {
                        isShowingUserPID.toggle()
                    }
                    Link(destination: URL(string: "https://myportal.circle.ms/")!) {
                        HStack(alignment: .center) {
                            Text("Profile.Edit")
                            Spacer()
                            Image(systemName: "safari")
                                .foregroundStyle(.secondary)
                        }
                    }
                    Button("Shared.LoginAgain", role: .destructive) {
                        authManager.token = nil
                    }
                }
                Section {
                    ForEach(user.circles, id: \.eventID) { event in
                        Text(event.name)
                    }
                } header: {
                    ListSectionHeader(text: "More.Events")
                }
                Section {
                    NavigationLink(value: ViewPath.moreDBAdmin) {
                        ListRow(image: "ListIcon.MasterDB", title: "More.DBAdmin.ManageDB")
                    }
                } header: {
                    ListSectionHeader(text: "More.DBAdmin")
                }
            }
            .task {
                if let token = authManager.token {
                    await user.getUser(authToken: token)
                    await user.getEvents(authToken: token)
                }
            }
            .navigationDestination(for: ViewPath.self) { viewPath in
                switch viewPath {
                case .moreDBAdmin: MoreDatabaseAdministratiion()
                case .moreAttributions:
                    LicensesView(licenses: [
                        License(libraryName: "KeychainAccess", text: """
The MIT License (MIT)

Copyright (c) 2014 kishikawa katsumi

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.


"""),
                        License(libraryName: "SQlite.swift", text: """
(The MIT License)

Copyright (c) 2014-2015 Stephen Celis (<stephen@stephencelis.com>)

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
"""),
                        License(libraryName: "ZIPFoundation", text: """
MIT License

Copyright (c) 2017-2024 Thomas Zoechling (https://www.peakstep.com)

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

""")
                    ])
                default: Color.clear
                }
            }
        }
    }
}
