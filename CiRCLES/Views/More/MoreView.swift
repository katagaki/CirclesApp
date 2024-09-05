//
//  MoreView.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2024/07/15.
//

import Komponents
import SwiftData
import SwiftUI

struct MoreView: View {
    @EnvironmentObject var navigationManager: NavigationManager
    @Environment(AuthManager.self) var authManager
    @Environment(DatabaseManager.self) var database

    @AppStorage(wrappedValue: false, "Customization.ShowSpaceName") var showSpaceName: Bool
    @AppStorage(wrappedValue: false, "Customization.ShowDay") var showDay: Bool

    var body: some View {
        NavigationStack(path: $navigationManager[.more]) {
            MoreList(repoName: "katagaki/CirclesApp", viewPath: ViewPath.moreAttributions) {
                Section {
                    Toggle("More.Customization.ShowHallAndBlock", isOn: $showSpaceName)
                    Toggle("More.Customization.ShowDay", isOn: $showDay)
                } header: {
                    ListSectionHeader(text: "More.Customization")
                }
                Section {
                    Group {
                        switch Locale.current.language.languageCode {
                        case .japanese:
                            Link(destination: URL(string: "https://www.bigsight.jp/visitor/floormap/")!) {
                                HStack(alignment: .center) {
                                    ListRow(image: "ListIcon.BigSight", title: "More.UsefulResources.BigSightMap")
                                        .foregroundStyle(.foreground)
                                    Spacer()
                                    Image(systemName: "safari")
                                        .foregroundStyle(.foreground.opacity(0.5))
                                }
                            }
                            Link(destination: URL(string: "https://webcatalog.circle.ms")!) {
                                HStack(alignment: .center) {
                                    ListRow(image: "ListIcon.WebCatalog", title: "More.UsefulResources.WebCatalog")
                                        .foregroundStyle(.foreground)
                                    Spacer()
                                    Image(systemName: "safari")
                                        .foregroundStyle(.foreground.opacity(0.5))
                                }
                            }
                        default:
                            Link(destination: URL(string: "https://www.bigsight.jp/english/visitor/floormap/")!) {
                                HStack(alignment: .center) {
                                    ListRow(image: "ListIcon.BigSight", title: "More.UsefulResources.BigSightMap")
                                        .foregroundStyle(.foreground)
                                    Spacer()
                                    Image(systemName: "safari")
                                        .foregroundStyle(.foreground.opacity(0.5))
                                }
                            }
                            Link(destination: URL(string: "https://int.webcatalog.circle.ms/en/catalog")!) {
                                HStack(alignment: .center) {
                                    ListRow(image: "ListIcon.WebCatalog", title: "More.UsefulResources.WebCatalog")
                                        .foregroundStyle(.foreground)
                                    Spacer()
                                    Image(systemName: "safari")
                                        .foregroundStyle(.foreground.opacity(0.5))
                                }
                            }
                        }
                    }
                } header: {
                    ListSectionHeader(text: "More.UsefulResources")
                }
                Section {
                    NavigationLink(value: ViewPath.moreDBAdmin) {
                        ListRow(image: "ListIcon.MasterDB", title: "More.DBAdmin.ManageDB")
                    }
                } header: {
                    ListSectionHeader(text: "More.DBAdmin")
                } footer: {
                    VStack(alignment: .leading, spacing: 20.0) {
                        Text("More.ProvidedBy")
                        Text("More.Disclaimer")
                    }
                    .font(.body)
                    .padding([.top], 20.0)
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
