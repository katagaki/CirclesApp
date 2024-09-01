//
//  DataFetcher.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2024/09/01.
//

import Foundation
import SwiftData

@ModelActor
actor DataFetcher {

    func blockName(_ id: Int) -> String? {
        let fetchDescriptor = FetchDescriptor<ComiketBlock>(
            predicate: #Predicate<ComiketBlock> {
                $0.id == id
            }
        )
        do {
            let block = (try modelContext.fetch(fetchDescriptor)).first
            if let block {
                return block.name
            }
        } catch {
            debugPrint(error.localizedDescription)
        }
        return nil
    }

    func dates(for eventNumber: Int) -> [Int: Date] {
        let fetchDescriptor = FetchDescriptor<ComiketDate>(
            predicate: #Predicate<ComiketDate> {
                $0.eventNumber == eventNumber
            },
            sortBy: [SortDescriptor(\.id, order: .forward)]
        )
        do {
            let dates = try modelContext.fetch(fetchDescriptor)
            var dayAndDate: [Int: Date] = [:]
            for date in dates {
                dayAndDate[date.id] = date.date
            }
            return dayAndDate
        } catch {
            debugPrint(error.localizedDescription)
            return [:]
        }
    }
}
