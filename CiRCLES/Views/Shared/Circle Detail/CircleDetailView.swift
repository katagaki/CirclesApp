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
    @Environment(Events.self) var planner
    @Environment(Unifier.self) var unifier

    @State var circle: ComiketCircle

    @State var extendedInformation: ComiketCircleExtendedInformation?
    @State var webCatalogInformation: WebCatalogCircle?
    @State var genre: String?

    @State var previousCircle: ((ComiketCircle) -> ComiketCircle?)?
    @State var nextCircle: ((ComiketCircle) -> ComiketCircle?)?
    @State var isFirstCircleAlertShowing: Bool = false
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
                    .onTapGesture {
                        let circleID = circle.id
                        let eventNumber = planner.activeEventNumber
                        Task.detached {
                            let actor = VisitActor(modelContainer: sharedModelContainer)
                            await actor.toggleVisit(circleID: circleID, eventNumber: eventNumber)
                        }
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
            if circle.supplementaryDescription.trimmingCharacters(in: .whitespacesAndNewlines).count > 0 {
                ListSectionWithTranslateButton(title: "Shared.Description", text: circle.supplementaryDescription)
            } else {
                Section {
                    Text("Circles.NoDescription")
                        .foregroundStyle(.secondary)
                } header: {
                    Text("Shared.Description")
                }
            }
            if circle.bookName.trimmingCharacters(in: .whitespacesAndNewlines) != "" {
                ListSectionWithTranslateButton(title: "Shared.BookName", text: circle.bookName)
            }
            if let genre {
                ListSectionWithTranslateButton(title: "Shared.Genre", text: genre)
            }
            if let tags = webCatalogInformation?.tag, tags.trimmingCharacters(in: .whitespaces).count > 0 {
                ListSectionWithTranslateButton(title: "Shared.Tags", text: tags)
            }
            if circle.memo.trimmingCharacters(in: .whitespacesAndNewlines).count > 0 {
                ListSectionWithTranslateButton(title: "Shared.Memo", text: circle.memo)
            }
        }
        .opacity(unifier.isMinimized ? 0.0 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: unifier.selectedDetent)
        .listSectionSpacing(.compact)
        .navigationTitle(circle.circleName)
        .navigationBarTitleDisplayMode(.inline)
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
                        goToPreviousCircle()
                    }
                    Button("Circles.GoNext", systemImage: "chevron.right") {
                        goToNextCircle()
                    }
                }
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0.0) {
            if let extendedInformation {
                if #available(iOS 26.0, *) {
                    CircleDetailToolbar(extendedInformation, webCatalogInformation)
                } else {
                    BarAccessory(placement: .bottom) {
                        VStack(spacing: 12.0) {
                            CircleDetailToolbar(extendedInformation, webCatalogInformation)
                        }
                        .padding(.vertical, 12.0)
                    }
                }
            }
        }
        .alert("Alerts.FirstCircle.Title", isPresented: $isFirstCircleAlertShowing) {
            Button("Shared.OK", role: .cancel) {
                isFirstCircleAlertShowing = false
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
        .onChange(of: circle.id) {
            Task {
                await prepareCircle()
            }
        }
    }

    func prepareCircle() async {
        if let extendedInformation = circle.extendedInformation {
            withAnimation(.smooth.speed(2.0)) {
                self.extendedInformation = extendedInformation
            }
        }
        if let token = authenticator.token, let extendedInformation {
            if let circleResponse = await WebCatalog.circle(
                with: extendedInformation.webCatalogID, authToken: token
            ),
               let webCatalogInformation = circleResponse.response.circle {
                withAnimation(.smooth.speed(2.0)) {
                    self.webCatalogInformation = webCatalogInformation
                }
            }
        }
        let actor = DataFetcher(modelContainer: sharedModelContainer)
        if let genre = await actor.genre(circle.genreID) {
            self.genre = genre
        }
    }

    func goToPreviousCircle() {
        if let previousCircle {
            if let circle = previousCircle(circle) {
                self.circle = circle
                Task {
                    await prepareCircle()
                }
            } else {
                isFirstCircleAlertShowing = true
            }
        } else {
            let circleID = circle.id - 1
            if !goToCircle(with: circleID) {
                isFirstCircleAlertShowing = true
            }
        }
    }

    func goToNextCircle() {
        if let nextCircle {
            if let circle = nextCircle(circle) {
                self.circle = circle
                Task {
                    await prepareCircle()
                }
            } else {
                isLastCircleAlertShowing = true
            }
        } else {
            let circleID = circle.id + 1
            if !goToCircle(with: circleID) {
                isLastCircleAlertShowing = true
            }
        }
    }

    func goToCircle(with id: Int) -> Bool {
        let fetchDescriptor = FetchDescriptor<ComiketCircle>(
            predicate: #Predicate<ComiketCircle> {
                $0.id == id
            }
        )
        let circles = try? modelContext.fetch(fetchDescriptor)
        if let circles, circles.count == 1 {
            self.circle = circles.first ?? self.circle
            Task {
                await prepareCircle()
            }
            return true
        } else {
            return false
        }
    }
}
