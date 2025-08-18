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
    @Environment(Authenticator.self) var authenticator
    @Environment(Database.self) var database

    @AppStorage(wrappedValue: true, "Customization.UseHighResolutionMaps") var useHighResolutionMaps: Bool
    @AppStorage(wrappedValue: true, "Customization.UseDarkModeMaps") var useDarkModeMaps: Bool
    @AppStorage(wrappedValue: false, "Customization.ShowSpaceName") var showSpaceName: Bool
    @AppStorage(wrappedValue: false, "Customization.ShowDay") var showDay: Bool
    @AppStorage(wrappedValue: false, "Customization.ShowWebCut") var showWebCut: Bool

    var body: some View {
        MoreList(repoName: "katagaki/CirclesApp", viewPath: UnifiedPath.moreAttributions) {
            Section {
                Toggle("More.Customization.Map.UseHighDefinitionMap", isOn: $useHighResolutionMaps)
                Toggle("More.Customization.Map.UseDarkModeMap", isOn: $useDarkModeMaps)
            } header: {
                ListSectionHeader(text: "More.Customization.Map")
            }
            Section {
                Toggle("More.Customization.Circles.ShowWebCut", isOn: $showWebCut)
                Toggle("More.Customization.Circles.ShowHallAndBlock", isOn: $showSpaceName)
                Toggle("More.Customization.Circles.ShowDay", isOn: $showDay)
            } header: {
                ListSectionHeader(text: "More.Customization.Circles")
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
                NavigationLink(value: UnifiedPath.moreDBAdmin) {
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
        .navigationDestination(for: UnifiedPath.self) { path in
            switch path {
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
                    License(libraryName: "libwebp", text: """
Copyright (c) 2010, Google Inc. All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are
met:

* Redistributions of source code must retain the above copyright
notice, this list of conditions and the following disclaimer.

* Redistributions in binary form must reproduce the above copyright
notice, this list of conditions and the following disclaimer in
the documentation and/or other materials provided with the
distribution.

* Neither the name of Google nor the names of its contributors may
be used to endorse or promote products derived from this software
without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
"AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
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
                    License(libraryName: "Swift-WebP", text: """
MIT License

Copyright (c) 2016 Satoshi Namai

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
