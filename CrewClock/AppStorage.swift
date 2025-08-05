//
//  AppStorage.swift
//  CrewClock
//
//  Created by Edgars Yarmolatiy on 7/23/25.
//

import SwiftUI

struct app {
    @AppStorage("fcmToken") static var fcmToken: String?
    /*@AppStorage("hasSeenOnboarding") */static var hasSeenOnboarding = false

}
