//
//  CircleDetailView.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2024/07/21.
//

import Komponents
import SwiftData
import SwiftUI
import Translation

struct CircleDetailView: View {

    @Environment(\.modelContext) var modelContext
    @Environment(Authenticator.self) var authenticator
    @Environment(Database.self) var database

    @State var circle: ComiketCircle

    @State var extendedInformation: ComiketCircleExtendedInformation?
    @State var webCatalogInformation: WebCatalogCircle?
    @State var genre: String?

    @State var isLastCircleAlertShowing: Bool = false

    @Namespace var namespace

    var body: some View {
        List {
            Section {
                VStack(spacing: 2.0) {
                    HStack(spacing: 6.0) {
                        Group {
                            Text("Circles.Image.Catalog")
                            if authenticator.onlineState == .online {
                                Text("Circles.Image.Web")
                            }
                        }
                        .textCase(.uppercase)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                    }
                    HStack(spacing: 6.0) {
                        Group {
                            CircleCutImage(
                                circle,
                                in: namespace,
                                showSpaceName: .constant(false),
                                showDay: .constant(false)
                            )
                            if authenticator.onlineState == .online {
                                CircleCutImage(
                                    circle,
                                    in: namespace,
                                    shouldFetchWebCut: true,
                                    showCatalogCut: false,
                                    forceWebCutUpdate: true,
                                    showSpaceName: .constant(false),
                                    showDay: .constant(false)
                                )
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: 250.0)
                    }
                }
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
                .listRowInsets(.init(top: 0.0, leading: 20.0, bottom: 0.0, trailing: 20.0))
                HStack(spacing: 5.0) {
                    CircleBlockPill("Shared.\(circle.day)th.Day", size: .large)
                    if let circleSpaceName = circle.spaceName() {
                        CircleBlockPill(LocalizedStringKey(circleSpaceName), size: .large)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.bottom, 2.0)
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
                .listRowInsets(.init(top: 10.0, leading: 20.0, bottom: 0.0, trailing: 20.0))
            }
            Section {
                if circle.supplementaryDescription.trimmingCharacters(in: .whitespacesAndNewlines).count > 0 {
                    Text(circle.supplementaryDescription)
                        .textSelection(.enabled)
                } else {
                    Text("Circles.NoDescription")
                        .foregroundStyle(.secondary)
                }
            } header: {
                HStack {
                    ListSectionHeader(text: "Shared.Description")
                    Spacer()
                    if circle.supplementaryDescription.trimmingCharacters(in: .whitespacesAndNewlines).count > 0 {
                        TranslateButton(translating: circle.supplementaryDescription)
                    }
                }
            }
            if circle.bookName.trimmingCharacters(in: .whitespacesAndNewlines) != "" {
                Section {
                    Text(circle.bookName)
                } header: {
                    HStack {
                        ListSectionHeader(text: "Shared.BookName")
                        Spacer()
                        if circle.bookName.trimmingCharacters(in: .whitespacesAndNewlines).count > 0 {
                            TranslateButton(translating: circle.bookName)
                        }
                    }
                }
            }
            if let genre {
                Section {
                    Text(genre)
                        .textSelection(.enabled)
                } header: {
                    HStack {
                        ListSectionHeader(text: "Shared.Genre")
                        Spacer()
                        TranslateButton(translating: genre)
                    }
                }
            }
            if let tags = webCatalogInformation?.tag, tags.trimmingCharacters(in: .whitespaces).count > 0 {
                Section {
                    Text(tags)
                        .textSelection(.enabled)
                } header: {
                    HStack {
                        ListSectionHeader(text: "Shared.Tags")
                        Spacer()
                        TranslateButton(translating: tags)
                    }
                }
            }
            if circle.memo.trimmingCharacters(in: .whitespacesAndNewlines).count > 0 {
                Section {
                    Text(circle.memo)
                        .textSelection(.enabled)
                }
            }
        }
        .navigationTitle(circle.circleName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .tabBar)
        .toolbar {
            ToolbarItem(placement: .principal) {
                VStack(spacing: 0.0) {
                    Text(circle.circleName)
                        .bold()
                    if circle.penName.trimmingCharacters(in: .whitespaces) != "" {
                        Text(circle.penName)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                HStack {
                    Button("Circles.GoPrevious", systemImage: "chevron.left") {
                        // Go to circle with previous ID
                        let circleID = circle.id - 1
                        let fetchDescriptor = FetchDescriptor<ComiketCircle>(
                            predicate: #Predicate<ComiketCircle> {
                                $0.id == circleID
                            }
                        )
                        let circles = try? modelContext.fetch(fetchDescriptor)
                        if let circles, circles.count == 1 {
                            self.circle = circles.first ?? self.circle
                            Task {
                                await prepareCircle()
                            }
                        }
                    }
                    .disabled(circle.id == 1)
                    Button("Circles.GoNext", systemImage: "chevron.right") {
                        // Go to circle with next ID
                        let circleID = circle.id + 1
                        let fetchDescriptor = FetchDescriptor<ComiketCircle>(
                            predicate: #Predicate<ComiketCircle> {
                                $0.id == circleID
                            }
                        )
                        let circles = try? modelContext.fetch(fetchDescriptor)
                        if let circles, circles.count == 1 {
                            self.circle = circles.first ?? self.circle
                            Task {
                                await prepareCircle()
                            }
                        } else {
                            isLastCircleAlertShowing = true
                        }
                    }
                }
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0.0) {
            ToolbarAccessory(placement: .bottom) {
                if let extendedInformation {
                    VStack(spacing: 12.0) {
                        CircleDetailToolbar(extendedInformation, webCatalogInformation)
                    }
                    .padding(.vertical, 12.0)
                }
            }
        }
        .alert("Alerts.LastCircle.Title", isPresented: $isLastCircleAlertShowing) {
            Button("Shared.OK", role: .cancel) {
                isLastCircleAlertShowing = false
            }
        }
        .task {
            await prepareCircle()
        }
        .onChange(of: circle.id) { _, _ in
            Task {
                await prepareCircle()
            }
        }
    }

    func prepareCircle() async {
        if let extendedInformation = circle.extendedInformation {
            withAnimation(.snappy.speed(2.0)) {
                self.extendedInformation = extendedInformation
            }
        }
        if let token = authenticator.token, let extendedInformation {
            if let circleResponse = await WebCatalog.circle(
                with: extendedInformation.webCatalogID, authToken: token
            ),
               let webCatalogInformation = circleResponse.response.circle {
                withAnimation(.snappy.speed(2.0)) {
                    self.webCatalogInformation = webCatalogInformation
                }
            }
        }
        let actor = DataFetcher(modelContainer: sharedModelContainer)
        if let genre = await actor.genre(circle.genreID) {
            self.genre = genre
        }
    }
}
