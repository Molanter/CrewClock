//
//  OnBoardingPages.swift
//  CrewClock
//
//  Created by Edgars Yarmolatiy on 8/5/25.
//

import SwiftUI

enum OnBoardingPages: CaseIterable {
    case welcome
    case organizeProjects
    case organizeLogsCalendar
    case connectWithOthers
    case organizeTasks
    case stayNotified

    var title: String {
        switch self {
        case .welcome:
            return "Welcome to CrewClock"
        case .organizeProjects:
            return "Organize Projects"
        case .organizeLogsCalendar:
            return "View Logs in Calendar"
        case .connectWithOthers:
            return "Connect With Your Crew"
        case .organizeTasks:
            return "Schedule Tasks"
        case .stayNotified:
            return "Stay Notified"
        }
    }

    var text: String {
        switch self {
        case .welcome:
            return "Track your hours, manage projects, and keep your team in sync - all in one place."
        case .organizeProjects:
            return "Create projects for every client or job, then switch between them with a tap."
        case .organizeLogsCalendar:
            return "See your daily and weekly time logs laid out on a calendar for at-a-glance planning."
        case .connectWithOthers:
            return "Invite team members, assign roles, and collaborate on projects seamlessly."
        case .organizeTasks:
            return "Assign tasks to crew members and schedule their work - you’ll never miss a deadline."
        case .stayNotified:
            return "Get real-time reminders and updates so you always know who’s working on what."
        }
    }
    
    var ps: String {
        switch self {
        case .welcome:
            return "Get started now to see how CrewClock can streamline your day!"
        case .organizeProjects:
            return "Customize each project with distinct colors for faster recognition."
        case .organizeLogsCalendar:
            return "Tap any day on the calendar to quickly review or add time logs."
        case .connectWithOthers:
            return "Invite teammates by email so everyone can collaborate on projects."
        case .organizeTasks:
            return "Plan ahead by assigning tasks and due dates to your crew members."
        case .stayNotified:
            return "Allow notifications to receive real-time reminders and updates."
        }
    }
    var image: String {
        switch self {
        case .welcome:
            return "👋"
        case .organizeProjects:
            return "📁"
        case .organizeLogsCalendar:
            return "📅"
        case .connectWithOthers:
            return "🤝"
        case .organizeTasks:
            return "🗓️"
        case .stayNotified:
            return "🔔"
        }
    }
}
