//
//  SettingsNavigationLinks.swift
//  CrewClock
//
//  Created by Edgars Yarmolatiy on 10/3/25.
//


import SwiftUI


enum SettingsNavigationLinks: CaseIterable, Identifiable, Hashable {
    case createTeam, viewTeams, preferences, appearance, notifications, faq, support, reportBug, exportLogs, deleteAccount, about, privacyPolicy, termsOfUse, myLogs
    
    var id: Self { self }
    
    // MARK: - Sectioning
    enum SectionID: String, CaseIterable {
        case teams        = "Teams"
        case personalization = "Personalization"
        case support      = "Support"
        case data         = "Data"
        case legal        = "Legal"
        case about        = "About"
        case danger       = "Danger Zone"
    }
    
    var section: SectionID {
        switch self {
        case .createTeam, .viewTeams:                 return .teams
        case .preferences, .appearance, .notifications: return .personalization
        case .faq, .support, .reportBug:              return .support
        case .exportLogs, .myLogs:                             return .data
        case .privacyPolicy, .termsOfUse:             return .legal
        case .about:                                  return .about
        case .deleteAccount:                          return .danger
        }
    }
    
    // Optional: fine-grained ordering within a section (lower comes first).
    // If you omit this, we’ll just sort alphabetically by title.
    var order: Int {
        switch self {
        case .createTeam: return 10
        case .viewTeams: return 20
        case .preferences: return 10
        case .appearance: return 20
        case .notifications: return 30
        case .faq: return 10
        case .support: return 20
        case .reportBug: return 30
        case .exportLogs: return 10
        case .myLogs: return 20
        case .privacyPolicy: return 10
        case .termsOfUse: return 20
        case .about: return 10
        case .deleteAccount: return 999 // keep this last in its section
        }
    }
    
    // MARK: - Existing properties
    var title: String {
        switch self {
        case .createTeam: return "Create Team"
        case .viewTeams: return "View Teams"
        case .preferences: return "Preferences"
        case .appearance: return "Appearance"
        case .notifications: return "Notifications"
        case .faq: return "FAQ"
        case .support: return "Support"
        case .reportBug: return "Report a Bug"
        case .exportLogs: return "Export Logs"
        case .myLogs: return "My Logs"
        case .deleteAccount: return "Delete Account"
        case .about: return "About"
        case .privacyPolicy: return "Privacy Policy"
        case .termsOfUse: return "Terms of Use"
        }
    }
    
    var image: String {
        switch self {
        case .createTeam: return "person.2.badge.plus"
        case .viewTeams: return "person.3"
        case .preferences: return "slider.horizontal.3"
        case .appearance: return "paintpalette"
        case .notifications: return "bell"
        case .faq: return "questionmark.bubble"
        case .support: return "wrench.and.screwdriver"
        case .reportBug: return "ladybug"
        case .exportLogs: return "square.and.arrow.up"
        case .myLogs: return "list.bullet"
        case .deleteAccount: return "person.fill.xmark"
        case .about: return "info.circle"
        case .privacyPolicy: return "hand.raised.circle"
        case .termsOfUse: return "list.bullet.circle"
        }
    }
    
    var color: Color {
        switch self {
        // MARK: - Teams
        case .createTeam: return .green        // positive, “add” action
        case .viewTeams: return .yellow        // organization-related

        // MARK: - Personalization
        case .preferences: return .teal        // neutral, thoughtful choice
        case .appearance: return K.Colors.accent // your app’s accent
        case .notifications: return .orange     // attention / alerts

        // MARK: - Support
        case .faq: return .purple              // curiosity / help
        case .support: return .mint            // calm, “we got you”
        case .reportBug: return .pink          // stands out without red danger

        // MARK: - Data
        case .exportLogs: return .cyan         // neutral “output/export”
        case .myLogs: return .indigo

        // MARK: - Danger / destructive
        case .deleteAccount: return .red       // warning/destructive

        // MARK: - About / Legal
        case .about: return .gray              // neutral / informational
        case .privacyPolicy: return .gray.opacity(0.8)
        case .termsOfUse: return .gray.opacity(0.8)
        }
    }
    
    @ViewBuilder
    var destination: some View {
        switch self {
        case .createTeam:
            CreateTeamView()
        case .viewTeams:
            MyTeamsView()
        case .preferences:
            Text("Time Tracking Preferences View")
        case .appearance:
            AppearanceView()
        case .notifications:
            NotificationsView()
        case .faq:
            FAQListView()
        case .support:
            SupportView()
        case .reportBug:
            ReportBugView()
        case .exportLogs:
            Text("Export Logs View")
        case .myLogs:
            LogsTabView()
        case .deleteAccount:
            EmptyView()
        case .about:
            AppOverviewView()
        case .privacyPolicy:
            WebView(url: K.Links.privacyPolicy)
                .edgesIgnoringSafeArea(.bottom)
                .tint(K.Colors.accent)
        case .termsOfUse:
            WebView(url: K.Links.termsOfUse)
                .edgesIgnoringSafeArea(.bottom)
                .tint(K.Colors.accent)
        }
    }
}

