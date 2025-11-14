//
//  ChecklistItem.swift
//  CrewClock
//
//  Created by Edgars Yarmolatiy on 6/12/25.
//

import SwiftUI

struct ChecklistItem: Identifiable, Codable, Equatable {
    let id: UUID
    var text: String
    var isChecked: Bool

    init(id: UUID = UUID(), text: String, isChecked: Bool = false) {
        self.id = id
        self.text = text
        self.isChecked = isChecked
    }
}
