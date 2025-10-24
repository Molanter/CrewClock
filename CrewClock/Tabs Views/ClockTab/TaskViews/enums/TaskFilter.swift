//
//  TaskFilter.swift
//  CrewClock
//
//  Created by Edgars Yarmolatiy on 10/15/25.
//

import SwiftUI

enum TaskFilter: String, CaseIterable, Identifiable {
    case assignedToMe = "Assigned"
    case createdByMe  = "Created"
    case all          = "All"
    var id: String { rawValue }
}
