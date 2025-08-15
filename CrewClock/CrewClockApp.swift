//
//  CrewClockApp.swift
//  CrewClock
//
//  Created by Edgars Yarmolatiy on 5/27/25.
//

import SwiftUI
import FirebaseCore
import FirebaseMessaging
import UIKit

@main
struct CrewClockApp: App {
    // register app delegate for Firebase setup
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    @StateObject private var authVM: AuthViewModel = .init()
    @StateObject private var sheetVM: SpreadSheetViewModel = .init()
    @StateObject private var logsVM: LogsViewModel = .init()
    @StateObject private var projectVM: ProjectViewModel = .init()
    @StateObject private var userVM: UserViewModel = .init()
    @StateObject private var searchUserVM: SearchUserViewModel = .init()
    @StateObject private var notificationsVM: NotificationsViewModel = .init()
    @StateObject private var connectionsVM: ConnectionsViewModel = .init()
    @StateObject private var publishedVariables: PublishedVariebles = .init()
    
    
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authVM)
                .environmentObject(sheetVM)
                .environmentObject(logsVM)
                .environmentObject(projectVM)
                .environmentObject(userVM)
                .environmentObject(searchUserVM)
                .environmentObject(notificationsVM)
                .environmentObject(connectionsVM)
                .environmentObject(publishedVariables)
        }
    }
}
