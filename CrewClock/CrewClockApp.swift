//
//  CrewClockApp.swift
//  CrewClock
//
//  Created by Edgars Yarmolatiy on 5/27/25.
//

import SwiftUI
import FirebaseCore
import UIKit

class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    FirebaseApp.configure()
      print("GIDClientID: \(Bundle.main.infoDictionary?["GIDClientID"] ?? "Not Found")")
    return true
  }
}

@main
struct CrewClockApp: App {
    // register app delegate for Firebase setup
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var authViewModel: AuthViewModel = .init()
    @StateObject private var sheetViewModel: SpreadSheetViewModel = .init()
    @StateObject private var logsViewModel: LogsViewModel = .init()
    @StateObject private var projectViewModel: ProjectViewModel = .init()
    @StateObject private var userViewModel: UserViewModel = .init()
    @StateObject private var searchUserViewModel: SearchUserViewModel = .init()
    @StateObject private var publishedVariables: PublishedVariebles = .init()



    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authViewModel)
                .environmentObject(sheetViewModel)
                .environmentObject(logsViewModel)
                .environmentObject(projectViewModel)
                .environmentObject(userViewModel)
                .environmentObject(publishedVariables)
                .environmentObject(searchUserViewModel)
        }
    }
}
