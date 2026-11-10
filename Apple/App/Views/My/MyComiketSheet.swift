import SwiftUI
import RADiUS
import AXiS
import Komponents

struct MyComiketSheet: View {

    @Environment(Authenticator.self) var authenticator
    @Environment(Database.self) var database
    @Environment(Events.self) var planner
    @Environment(Oasis.self) var oasis

    @State var path: [MyComiketPath] = []
    @State var eventTitle: String = ""

    @AppStorage("My.LastKnownNickname") var lastKnownNickname: String?
    @AppStorage(wrappedValue: 0, "My.LastKnownPID") var lastKnownPID: Int

    var body: some View {
        @Bindable var oasis = oasis
        NavigationStack(path: $path) {
            List {
                MyAccountSection()
                MyDataSection()
                MyMapAppearanceSection()
                MyCircleAppearanceSection()
                MyModesSection()
                if !authenticator.isOfflineModeActive {
                    MyDirectionsSection()
                    MyUsefulInformationSection()
                }
                MyAboutSection()
            }
            .navigationTitle("ViewTitle.My")
            .navigationSubtitle(eventTitle)
            .toolbarTitleDisplayMode(.inlineLarge)
            .toolbar {
                MyComiketToolbar()
            }
            .navigationDestination(for: MyComiketPath.self) { path in
                switch path {
                case .account: MyView()
                case .eventData: EventDataView()
                case .backup: BackupView()
                case .attributions: MoreLicensesView()
                }
            }
        }
        .progressAlert(
            isModal: .constant(true),
            isShowing: $oasis.isShowing,
            headerText: $oasis.headerText,
            bodyText: $oasis.bodyText,
            progress: $oasis.progress
        )
        .task(id: planner.activeEventNumber) {
            eventTitle = database.events()
                .first(where: { $0.eventNumber == planner.activeEventNumber })?.name ?? ""
        }
        .task {
            await refreshNickname()
        }
    }

    func refreshNickname() async {
        guard authenticator.effectiveOnlineState != .offline,
              let token = authenticator.token, !token.accessToken.isEmpty,
              let userInfo = await User.info(authToken: token) else { return }
        lastKnownNickname = userInfo.nickname
        lastKnownPID = userInfo.pid
    }
}
