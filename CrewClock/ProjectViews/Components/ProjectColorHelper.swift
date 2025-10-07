//
//   ProjectColorHelper.swift
//  CrewClock
//
//  Created by Edgars Yarmolatiy on 6/6/25.
//

import SwiftUI

struct ProjectColorHelper {
    static func color(for name: String?) -> Color {
        guard let colorName = name?.lowercased() else {
            return Color.gray
        }

        switch colorName {
        case "blue":
            return Color.blue
        case "yellow":
            return Color.yellow
        case "orange":
            return Color.orange
        case "cian", "cyan":
            return Color.cyan
        case "red":
            return Color.red
        case "green":
            return Color.green
        case "mint":
            return Color.mint
        case "purple":
            return Color.purple
        case "indigo":
            return Color.indigo
        case "brown":
            return Color.brown
        case "pink":
            return Color.pink
        default:
            return Color.red
        }
    }
}
