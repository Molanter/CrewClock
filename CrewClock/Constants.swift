//
//  Constants.swift
//  CrewClock
//
//  Created by Edgars Yarmolatiy on 6/12/25.
//

import SwiftUI

struct K {
    struct AppConstants {
//        @AppStorage("saveSpreadSheets") static var saveSpreadSheets: Bool = false

    }
    
    struct Colors {
        static var accent = Color.indigo
    }

    struct Fonts {
        static var heading = "Helvetica-Bold"
        static var body = "Helvetica"
    }

    struct Firestore {
        static var users = "users"
        static var logs = "logs"
        static var projects = "projects"
    }

    struct UI {
        static var cornerRadius: CGFloat = 15
        static var padding: CGFloat = 8
        static var opacity = 0.3
    }
}
