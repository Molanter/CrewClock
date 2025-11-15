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
        /// Key used for storing the accent color index in AppStorage/UserDefaults.
        static let accentIndexKey = "appearance.accentIndex"

        /// Accent color derived from the stored accent index.
        /// Falls back to `.green` if the index is out of range.
        static var accent: Color {
            let index = UserDefaults.standard.integer(forKey: accentIndexKey)
            if teamColors.indices.contains(index) {
                return teamColors[index]
            } else {
                return .green
            }
        }
        static var teamColors: [Color] = [.red, .blue, .yellow, .gray, .green, .purple, .orange, .pink, .indigo, .cyan]
        
        /// Returns a human‑readable name for a given SwiftUI `Color`.
        static func colorName(_ color: Color) -> String {
            switch color {
            case .red:
                return "Red"
            case .blue:
                return "Blue"
            case .yellow:
                return "Yellow"
            case .gray:
                return "Gray"
            case .green:
                return "Green"
            case .purple:
                return "Purple"
            case .orange:
                return "Orange"
            case .pink:
                return "Pink"
            case .indigo:
                return "Indigo"
            case .cyan:
                return "Cyan"
            default:
                return "Unknown"
            }
        }

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
        // MARK: - Keys for AppStorage / UserDefaults
        static let cornerRadiusKey = "appearance.cornerRadius"
        static let paddingKey = "appearance.padding"
        static let opacityKey = "appearance.opacity"

        // MARK: - Default values
        static let defaultCornerRadius: CGFloat = 30
        static let defaultPadding: CGFloat = 15
        static let defaultOpacity: Double = 0.3

        /// Corner radius used across the app. Backed by UserDefaults.
        static var cornerRadius: CGFloat {
            get {
                let stored = UserDefaults.standard.double(forKey: cornerRadiusKey)
                return stored == 0 ? defaultCornerRadius : stored
            }
            set {
                UserDefaults.standard.set(Double(newValue), forKey: cornerRadiusKey)
            }
        }

        /// Default padding used across the app. Backed by UserDefaults.
        static var padding: CGFloat {
            get {
                let stored = UserDefaults.standard.double(forKey: paddingKey)
                return stored == 0 ? defaultPadding : stored
            }
            set {
                UserDefaults.standard.set(Double(newValue), forKey: paddingKey)
            }
        }

        /// Default opacity used across the app. Backed by UserDefaults.
        static var opacity: Double {
            get {
                let stored = UserDefaults.standard.double(forKey: opacityKey)
                return stored == 0 ? defaultOpacity : stored
            }
            set {
                UserDefaults.standard.set(newValue, forKey: opacityKey)
            }
        }
    }
    struct Emoji {
        static var emojiNothingArray = [
            "zzz" : "https://firebasestorage.googleapis.com/v0/b/crewclock-9a62b.firebasestorage.app/o/emoji%2FAnimatedEmojies-512px-155.gif?alt=media&token=18b0550c-2ab6-4421-a2be-fcb0a6ca8a42",
            "stone_face" : "https://firebasestorage.googleapis.com/v0/b/crewclock-9a62b.firebasestorage.app/o/emoji%2FAnimatedEmojies-512px-144.gif?alt=media&token=2ccbe702-6bc3-40e4-8b18-d2f099c310c2",
            "no_mouth" : "https://firebasestorage.googleapis.com/v0/b/crewclock-9a62b.firebasestorage.app/o/emoji%2FAnimatedEmojies-512px-205.gif?alt=media&token=a219b0e5-e5ec-4d5f-9d5d-35aba93d377d",
            "face_in_steam" : "https://firebasestorage.googleapis.com/v0/b/crewclock-9a62b.firebasestorage.app/o/emoji%2FAnimatedEmojies-512px-327.gif?alt=media&token=aeb8e45e-c33e-4839-85dd-fd501318d6e6",
            "human_footsteps" : "https://firebasestorage.googleapis.com/v0/b/crewclock-9a62b.firebasestorage.app/o/emoji%2FAnimatedEmojies-512px-336.gif?alt=media&token=ef477044-982e-489c-87be-c8c622202742",
            "cat_fotsteps" : "https://firebasestorage.googleapis.com/v0/b/crewclock-9a62b.firebasestorage.app/o/emoji%2FAnimatedEmojies-512px-341.gif?alt=media&token=5c63b2e2-b1fb-43e3-9949-cb02fe5132e5",
            "no_eyes_monkey" : "https://firebasestorage.googleapis.com/v0/b/crewclock-9a62b.firebasestorage.app/o/emoji%2FAnimatedEmojies-512px-21.gif?alt=media&token=b2d687dc-30ea-4448-b28c-e43abf83147f",
            "spiderweb" : "https://firebasestorage.googleapis.com/v0/b/crewclock-9a62b.firebasestorage.app/o/emoji%2FAnimatedEmojies-512px-369.gif?alt=media&token=4a3a5eb5-1e40-41bc-9ea1-dc4139017dfc",
            "big_eyes" : "https://firebasestorage.googleapis.com/v0/b/crewclock-9a62b.firebasestorage.app/o/emoji%2FAnimatedEmojies-512px-384.gif?alt=media&token=dcf7984d-b857-4854-b304-b880e9ef052f"
        ]
    }
    
    struct SFSymbols {
        static var teamArray: [String] = [
            "person.3",
            "folder",
            "hammer",
            "gearshape",
            "paperclip",
            "pencil.and.scribble",
            "paperplane",
            "book.pages",
            "graduationcap",
            "pencil.and.ruler",
            "figure.fall",
            "medal",
            "globe",
            "sos",
            "wand.and.sparkles",
            "wrench.and.screwdriver",
            "theatermasks",
            "house",
            "lightbulb.max",
            "popcorn",
            "finder",
            "airplane.up.right",
            "car",
            "sailboat",
            "lizard.fill",
            "dog.fill",
            "bird.fill",
            "laurel.leading.laurel.trailing",
            "camera.macro",
            "tree",
            "movieclapper",
            "face.dashed",
            "brain.filled.head.profile",
            "shippingbox.fill",
            "alarm",
            "fork.knife",
            "waveform.path",
            "touchid",
            "compass.drawing",
            "skew",
            "checklist",
            "ellipsis.curlybraces",
            "dollarsign.circle"
        ]
    }
    
    struct Links {
        static var privacyPolicy: URL = URL(string: "https://www.notion.so/Privacy-Policy-Crew-s-Clock-246e6ff13e478094a947c537ad6893db")!
        static var termsOfUse: URL = URL(string: "https://www.notion.so/Terms-of-Use-Crew-s-Clock-246e6ff13e47809d922af3828fff2af3")!
    }
    
    struct Logs {
        static let dummyLog = LogFB(
            data: [
                "spreadsheetId": "",
                "row": 0,
                "projectName": "",
                "comment": "",
                "date": Date(),
                "timeStarted": Date(),
                "timeFinished": Date(),
                "crewUID": [],
                "expenses": 0.0
            ],
            documentId: "dummy"
        )
    }
}

