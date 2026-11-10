import SwiftUI

struct MyDataSection: View {

    var body: some View {
        Section {
            NavigationLink(value: MyComiketPath.eventData) {
                MySettingsIconLabel(title: "ViewTitle.More.DBAdmin", systemImage: "externaldrive.fill", color: .red)
            }
            NavigationLink(value: MyComiketPath.backup) {
                MySettingsIconLabel(title: "More.Backup", systemImage: "icloud.fill", color: .cyan)
            }
        }
    }
}
