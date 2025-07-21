//
//  EmptyStateType.swift
//  CrewClock
//
//  Created by Edgars Yarmolatiy on 7/20/25.
//

import SwiftUI

enum EmptyStateType {
    case noActiveProjects
    case noFinishedProjects
    
    var text: String {
        switch self {
        case .noActiveProjects:
            return "No Active projects yet."
        case .noFinishedProjects:
            return "No Finished projects yet."
        }
    }
    
    var gif: URL?  {
        switch self {
        case .noActiveProjects:
            URL(string: "https://firebasestorage.googleapis.com/v0/b/crewclock-9a62b.firebasestorage.app/o/emoji%2FAnimatedEmojies-512px-369.gif?alt=media&token=4a3a5eb5-1e40-41bc-9ea1-dc4139017dfc")
        case .noFinishedProjects:
            URL(string: "https://firebasestorage.googleapis.com/v0/b/crewclock-9a62b.firebasestorage.app/o/emoji%2FAnimatedEmojies-512px-144.gif?alt=media&token=2ccbe702-6bc3-40e4-8b18-d2f099c310c2")
        }
    }
}
