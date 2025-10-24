//
//  Color.swift
//  CrewClock
//
//  Created by Edgars Yarmolatiy on 10/22/25.
//

import SwiftUI
import FirebaseFirestore

extension Color {
    // MARK: Decode from Firestore field
    init?(from firestoreValue: Any?) {
        if let hex = firestoreValue as? String {
            if let c = Color(hex: hex) {
                self = c
                return
            }
        }
        if let rgb = firestoreValue as? [String: Any],
           let rAny = rgb["r"], let gAny = rgb["g"], let bAny = rgb["b"] {
            let r = (rAny as? Double) ?? Double((rAny as? NSNumber)?.doubleValue ?? 0)
            let g = (gAny as? Double) ?? Double((gAny as? NSNumber)?.doubleValue ?? 0)
            let b = (bAny as? Double) ?? Double((bAny as? NSNumber)?.doubleValue ?? 0)
            let scale: Double = (r > 1.0 || g > 1.0 || b > 1.0) ? 255.0 : 1.0
            self = Color(red: r / scale, green: g / scale, blue: b / scale)
            return
        }
        return nil
    }

    static func from(_ document: DocumentSnapshot) -> Color {
        if let value = document["color"] {
            return Color(from: value) ?? .blue
        }
        return .blue
    }

    // MARK: Encode to Firestore (hex string)
    func toFirestoreValue() -> Any {
        return self.toHexString() ?? "#000000"
    }

    // MARK: Convert Color -> hex string
    func toHexString() -> String? {
        #if canImport(UIKit)
        let uiColor = UIColor(self)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        guard uiColor.getRed(&r, green: &g, blue: &b, alpha: &a) else { return nil }
        return String(format: "#%02lX%02lX%02lX",
                      lroundf(Float(r * 255)),
                      lroundf(Float(g * 255)),
                      lroundf(Float(b * 255)))
        #else
        return nil
        #endif
    }
}

extension Color {
    /// Initialize a Color from a hex string like "#RRGGBB" or "RRGGBB" (alpha defaults to 1.0)
    /// Returns nil if the string can't be parsed.
    init?(hexString: String) {
        // Normalize: remove leading '#', trim whitespace, uppercase for consistency
        let hex = hexString.trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: "#"))
            .uppercased()

        // Support RRGGBB or RRGGBBAA
        let length = hex.count
        guard length == 6 || length == 8 else { return nil }

        var value: UInt64 = 0
        guard Scanner(string: hex).scanHexInt64(&value) else { return nil }

        let r, g, b, a: UInt64
        if length == 6 {
            r = (value & 0xFF0000) >> 16
            g = (value & 0x00FF00) >> 8
            b = (value & 0x0000FF)
            a = 0xFF
        } else { // 8
            r = (value & 0xFF000000) >> 24
            g = (value & 0x00FF0000) >> 16
            b = (value & 0x0000FF00) >> 8
            a = (value & 0x000000FF)
        }

        let rf = Double(r) / 255.0
        let gf = Double(g) / 255.0
        let bf = Double(b) / 255.0
        let af = Double(a) / 255.0

        #if canImport(UIKit)
        self = Color(UIColor(red: rf, green: gf, blue: bf, alpha: af))
        #elseif canImport(AppKit)
        self = Color(NSColor(calibratedRed: rf, green: gf, blue: bf, alpha: af))
        #else
        self = Color(red: rf, green: gf, blue: bf, opacity: af)
        #endif
    }

    /// Convenience initializer to match existing call site `Color(hex: ...)`.
    init?(hex: String) {
        self.init(hexString: hex)
    }
}
