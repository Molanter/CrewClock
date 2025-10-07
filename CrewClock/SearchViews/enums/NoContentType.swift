//
//  NoContentType.swift
//  CrewClock
//
//  Created by Edgars Yarmolatiy on 7/20/25.
//

import SwiftUI

enum NoContentType {
    case noLogs
    case noResults
    case noUsers
    case search
    
    var title: String {
        switch self {
        case .noLogs:
            return "No logs yet..."
        case .noResults:
            return "No results found..."
        case .noUsers:
            return "No user found"
        case .search:
            return "Search user"
        }
    }
    
    var subtitle: String {
        switch self {
        case .noLogs:
            return "Create your first Log, or ClockIn."
        case .noResults:
            return "Try a different search term."
        case .noUsers:
            return "Check your spelling or search for different word."
        case .search:
            return "Search by name or email."
        }
    }
    
    var gif: URL?  {
        switch self {
        case .noLogs:
            URL(string: K.Emoji.emojiNothingArray.first?.value ?? "")
        case .noResults:
            URL(string: "https://firebasestorage.googleapis.com/v0/b/crewclock-9a62b.firebasestorage.app/o/emoji%2FAnimatedEmojies-512px-384.gif?alt=media&token=dcf7984d-b857-4854-b304-b880e9ef052f")
        case .noUsers:
            URL(string: "https://firebasestorage.googleapis.com/v0/b/crewclock-9a62b.firebasestorage.app/o/emoji%2FAnimatedEmojies-512px-384.gif?alt=media&token=dcf7984d-b857-4854-b304-b880e9ef052f")
        case .search:
            URL(string: "https://firebasestorage.googleapis.com/v0/b/crewclock-9a62b.firebasestorage.app/o/emoji%2FAnimatedEmojies-512px-205.gif?alt=media&token=a219b0e5-e5ec-4d5f-9d5d-35aba93d377d")
        }
    }
}
