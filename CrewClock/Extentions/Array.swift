//
//  Array.swift
//  CrewClock
//
//  Created by Edgars Yarmolatiy on 10/6/25.
//

/// MARK: - Helpers to group & sort
extension Array where Element == SettingsNavigationLinks {
    /// Groups items into sections and sorts both sections and items.
    func groupedAndSorted() -> [(SettingsNavigationLinks.SectionID, [SettingsNavigationLinks])] {
        let grouped = Dictionary(grouping: self, by: { $0.section })
        // Sort items in each section by `order`, then by `title`
        let sortedSections = SettingsNavigationLinks.SectionID.allCases.compactMap { section -> (SettingsNavigationLinks.SectionID, [SettingsNavigationLinks])? in
            guard let items = grouped[section] else { return nil }
            let sortedItems = items.sorted { lhs, rhs in
                if lhs.order != rhs.order { return lhs.order < rhs.order }
                return lhs.title.localizedStandardCompare(rhs.title) == .orderedAscending
            }
            return (section, sortedItems)
        }
        return sortedSections
    }
}
