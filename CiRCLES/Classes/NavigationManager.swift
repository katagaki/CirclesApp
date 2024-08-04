//
//  NavigationManager.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2024/07/15.
//

import Foundation

class NavigationManager: ObservableObject {

    let defaults = UserDefaults.standard
    let selectedTabKey = "NavigationManager.SelectedTab"

    @Published var selectedTab: TabType
    @Published var previouslySelectedTab: TabType
    @Published var tabPaths: [TabType: [ViewPath]] = [
        .map: [],
        .circles: [],
        .favorites: [],
        .more: []
    ]

    init() {
        if let selectedTab = TabType(rawValue: defaults.integer(forKey: selectedTabKey)) {
            self.selectedTab = selectedTab
            self.previouslySelectedTab = selectedTab
        } else {
            self.selectedTab = .map
            self.previouslySelectedTab = .map
        }
    }

    subscript(tabType: TabType) -> [ViewPath] {
        get {
            return tabPaths[tabType] ?? []
        }
        set(newViewPath) {
            tabPaths[tabType] = newViewPath
        }
    }

    func popToRoot(for tab: TabType) {
        tabPaths[tab]?.removeAll()
    }

    func push(_ viewPath: ViewPath, for tab: TabType) {
        tabPaths[tab]?.append(viewPath)
    }

    func saveToDefaults() {
        defaults.setValue(selectedTab.rawValue, forKey: selectedTabKey)
        defaults.synchronize()
    }
}
