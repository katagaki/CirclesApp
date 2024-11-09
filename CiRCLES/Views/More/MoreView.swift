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
    @EnvironmentObject var navigator: Navigator
    @Environment(AuthManager.self) var authManager
    @Environment(Database.self) var database

    @AppStorage(wrappedValue: true, "Customization.UseHighResolutionMaps") var useHighResolutionMaps: Bool
    @AppStorage(wrappedValue: false, "Customization.ShowSpaceName") var showSpaceName: Bool
    @AppStorage(wrappedValue: false, "Customization.ShowDay") var showDay: Bool

    var body: some View {
        NavigationStack(path: $navigator[.more]) {
            MoreList(repoName: "katagaki/CirclesApp", viewPath: ViewPath.moreAttributions) {
                Section {
                    Toggle("More.Customization.UseHighDefinitionMap", isOn: $useHighResolutionMaps)
                    Toggle("More.Customization.ShowHallAndBlock", isOn: $showSpaceName)
                    Toggle("More.Customization.ShowDay", isOn: $showDay)
                } header: {
                    ListSectionHeader(text: "More.Customization")
                }
                Section {
                    switch Locale.current.language.languageCode {
                    case .japanese:
                        if UIApplication.shared.canOpenURL(URL(string: "maps://")!) {
                            ExternalLink("maps://?saddr=現在地&daddr=東京ビッグサイト",
                                         title: "More.Navigate.Maps", image: "ListIcon.AppleMaps")
                        }
                        if UIApplication.shared.canOpenURL(URL(string: "comgooglemaps://")!) {
                            ExternalLink("comgooglemaps://?saddr=現在地&daddr=東京ビッグサイト",
                                         title: "More.Navigate.GoogleMaps", image: "ListIcon.GoogleMaps")
                        }
                        if UIApplication.shared.canOpenURL(URL(string: "yjmap://")!) {
                            ExternalLink("yjmap://route/train?from=現在地&to=東京ビッグサイト",
                                         title: "More.Navigate.YahooMap", image: "ListIcon.YahooMap")
                        }
                    default:
                        if UIApplication.shared.canOpenURL(URL(string: "maps://")!) {
                            ExternalLink("maps://?saddr=Current+Location&daddr=Tokyo+Big+Sight",
                                         title: "More.Navigate.Maps", image: "ListIcon.AppleMaps")
                        }
                        if UIApplication.shared.canOpenURL(URL(string: "comgooglemaps://")!) {
                            ExternalLink("comgooglemaps://?saddr=My+Location&daddr=Tokyo+Big+Sight",
                                         title: "More.Navigate.GoogleMaps", image: "ListIcon.GoogleMaps")
                        }
                    }
                } header: {
                    ListSectionHeader(text: "More.Navigate")
                }
                Section {
                    switch Locale.current.language.languageCode {
                    case .japanese:
                        SafariLink("https://webcatalog.circle.ms",
                                   title: "More.UsefulResources.WebCatalog", image: "ListIcon.WebCatalog")
                        SafariLink("https://comiket.co.jp",
                                   title: "More.UsefulResources.Comiket", image: "ListIcon.Comiket")
                        SafariLink("https://www.bigsight.jp/visitor/floormap/",
                                   title: "More.UsefulResources.BigSightMap", image: "ListIcon.BigSight")
                    default:
                        SafariLink("https://int.webcatalog.circle.ms/en/catalog",
                                   title: "More.UsefulResources.WebCatalog", image: "ListIcon.WebCatalog")
                        SafariLink("https://comiket.co.jp",
                                   title: "More.UsefulResources.Comiket", image: "ListIcon.Comiket")
                        SafariLink("https://www.bigsight.jp/english/visitor/floormap/",
                                   title: "More.UsefulResources.BigSightMap", image: "ListIcon.BigSight")
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
                }
                Section {
                    VStack(alignment: .leading, spacing: 20.0) {
                        Text("More.ProvidedBy")
                        Text("More.Disclaimer")
                    }
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .padding(.top, 20.0)
                    .listRowBackground(Color.clear)
                }
            }
            .listSectionSpacing(.compact)
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
                        License(libraryName: "Reachability.swift", text: """
Copyright (c) 2016 Ashley Mills

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
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
