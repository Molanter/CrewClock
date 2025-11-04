//
//  ReportBugViewModel.swift
//  CrewClock
//
//  Created by Edgars Yarmolatiy on 10/23/25.
//


import Foundation
import SwiftUI
import FirebaseFirestore
import FirebaseAuth

@MainActor
final class ReportBugViewModel: ObservableObject {
    // Form
    @Published var severity: Severity = .medium
    @Published var subject: String = ""
    @Published var stepsToReproduce: String = ""
    @Published var actualResult: String = ""
    @Published var includeDiagnostics: Bool = true

    // UI state
    @Published var isSending = false
    @Published var sendSuccess = false
    @Published var errorMessage: String?

    enum Severity: String, CaseIterable, Identifiable, Hashable {
        case low = "Low"
        case medium = "Medium"
        case high = "High"
        case critical = "Critical"
        var id: String { rawValue }
    }

    private let db = Firestore.firestore()

    var isValid: Bool {
        !subject.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !stepsToReproduce.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !actualResult.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func submit() async {
        errorMessage = nil
        sendSuccess = false
        guard isValid else {
            errorMessage = "Please fill Subject, Steps, and Actual result."
            return
        }

        isSending = true
        defer { isSending = false }

        var data: [String: Any] = [
            "subject": subject.trimmingCharacters(in: .whitespacesAndNewlines),
            "severity": severity.rawValue,
            "stepsToReproduce": stepsToReproduce.trimmingCharacters(in: .whitespacesAndNewlines),
            "actualResult": actualResult.trimmingCharacters(in: .whitespacesAndNewlines),
            "createdAt": FieldValue.serverTimestamp()
        ]
        if includeDiagnostics {
            data["diagnostics"] = diagnostics()
        }

        do {
            try await db.collection("bugReports").addDocument(data: data)
            sendSuccess = true
            // clear main fields (keep severity)
            subject = ""
            stepsToReproduce = ""
            actualResult = ""
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // Minimal safe diagnostics (strings only)
    private func diagnostics() -> [String: Any] {
        var d: [String: Any] = [:]

        if let info = Bundle.main.infoDictionary {
            let version = info["CFBundleShortVersionString"] as? String ?? "?"
            let build = info["CFBundleVersion"] as? String ?? "?"
            d["appVersion"] = "\(version) (\(build))"
        }

        #if os(iOS)
        d["systemVersion"] = UIDevice.current.systemVersion
        d["device"] = UIDevice.current.model
        #endif

        if let user = Auth.auth().currentUser {
            d["uid"] = user.uid
            d["email"] = user.email ?? ""
            d["displayName"] = user.displayName ?? ""
        }

        d["clientTime"] = ISO8601DateFormatter().string(from: Date())
        return d
    }
}
