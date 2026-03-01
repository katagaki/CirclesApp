//
//  CircleDetailSectionEditor.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2026/03/01.
//

import SwiftUI

struct CircleDetailSectionEditor: View {

    @Environment(\.dismiss) var dismiss

    @AppStorage(wrappedValue: "", "Circles.Detail.SectionOrder") var sectionOrderStorage: String
    @AppStorage(wrappedValue: "", "Circles.Detail.HiddenSections") var hiddenSectionsStorage: String

    @State var orderedSections: [CircleDetailSection] = CircleDetailSection.defaultOrder
    @State var hiddenSections: Set<CircleDetailSection> = []

    var body: some View {
        List {
            ForEach(orderedSections) { section in
                Toggle(isOn: Binding(
                    get: { !hiddenSections.contains(section) },
                    set: { isVisible in
                        if isVisible {
                            hiddenSections.remove(section)
                        } else {
                            hiddenSections.insert(section)
                        }
                    }
                )) {
                    Text(section.localizedName)
                }
            }
            .onMove { from, destination in
                orderedSections.move(fromOffsets: from, toOffset: destination)
            }
        }
        .environment(\.editMode, .constant(.active))
        .navigationTitle("Circles.Detail.SectionEditor.Title")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if #available(iOS 26.0, *) {
                    Button("Shared.Save", role: .confirm) {
                        save()
                    }
                } else {
                    Button("Shared.Save") {
                        save()
                    }
                }
            }
        }
        .onAppear {
            orderedSections = decodeSectionOrder(sectionOrderStorage)
            hiddenSections = Set(decodeHiddenSections(hiddenSectionsStorage))
        }
    }

    func save() {
        sectionOrderStorage = encodeSections(orderedSections)
        hiddenSectionsStorage = encodeSections(Array(hiddenSections))
        dismiss()
    }

    func encodeSections(_ sections: [CircleDetailSection]) -> String {
        let rawValues = sections.map(\.rawValue)
        if let data = try? JSONEncoder().encode(rawValues) {
            return String(data: data, encoding: .utf8) ?? ""
        }
        return ""
    }

    func decodeSectionOrder(_ string: String) -> [CircleDetailSection] {
        guard !string.isEmpty, let data = string.data(using: .utf8),
              let rawValues = try? JSONDecoder().decode([Int].self, from: data) else {
            return CircleDetailSection.defaultOrder
        }
        var sections = rawValues.compactMap { CircleDetailSection(rawValue: $0) }
        // Append any missing sections (e.g. newly added ones)
        for section in CircleDetailSection.allCases where !sections.contains(section) {
            sections.append(section)
        }
        return sections
    }

    func decodeHiddenSections(_ string: String) -> [CircleDetailSection] {
        guard !string.isEmpty, let data = string.data(using: .utf8),
              let rawValues = try? JSONDecoder().decode([Int].self, from: data) else {
            return []
        }
        return rawValues.compactMap { CircleDetailSection(rawValue: $0) }
    }
}
