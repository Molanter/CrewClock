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
    
    var title: String {
        switch self {
        case .noLogs:
            return "No logs yet..."
        case .noResults:
            return "No results found..."
        }
    }
    
    var subtitle: String {
        switch self {
        case .noLogs:
            return "Create your first Log, or ClockIn."
        case .noResults:
            return "Try a different search term."
        }
    }
    
    var gif: URL?  {
        switch self {
        case .noLogs:
            URL(string: K.Emoji.emojiNothingArray.first?.value ?? "")
        case .noResults:
            URL(string: "https://firebasestorage.googleapis.com/v0/b/crewclock-9a62b.firebasestorage.app/o/emoji%2FAnimatedEmojies-512px-384.gif?alt=media&token=dcf7984d-b857-4854-b304-b880e9ef052f")
        }
    }
}
