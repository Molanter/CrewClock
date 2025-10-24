//
//  SupportViewModel.swift
//  CrewClock
//
//  Created by Edgars Yarmolatiy on 10/23/25.
//


import Foundation
import SwiftUI
import FirebaseFirestore
import FirebaseAuth

@MainActor
final class SupportViewModel: ObservableObject {
    // Form fields
    @Published var category: Category = .question
    @Published var subject: String = ""
    @Published var message: String = ""
    @Published var includeDiagnostics: Bool = true

    // UI state
    @Published var isSending = false
    @Published var sendSuccess = false
    @Published var errorMessage: String?

    enum Category: String, CaseIterable, Identifiable {
        case bug = "Bug"
        case question = "Question"
        case account = "Account"
        case teams = "Teams"
        case projects = "Projects"
        case logs = "Logs"
        case notifications = "Notifications"
        case other = "Other"

        var id: String { rawValue }
    }

    private let db = Firestore.firestore()

    func submit() async {
        errorMessage = nil
        sendSuccess = false
        guard valid else {
            errorMessage = "Please add a subject and message."
            return
        }

        isSending = true
        defer { isSending = false }

        let diag = includeDiagnostics ? diagnostics() : [:]

        var payload: [String: Any] = [
            "category": category.rawValue,
            "subject": subject.trimmingCharacters(in: .whitespacesAndNewlines),
            "message": message.trimmingCharacters(in: .whitespacesAndNewlines),
            "createdAt": FieldValue.serverTimestamp()
        ]
        payload["diagnostics"] = diag

        do {
            try await db.collection("supportTickets").addDocument(data: payload)
            sendSuccess = true
            // clear form (keep category)
            subject = ""
            message = ""
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    var valid: Bool {
        !subject.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    // Minimal diagnostics—strings only
    private func diagnostics() -> [String: Any] {
        var d: [String: Any] = [:]

        // App version/build
        if let info = Bundle.main.infoDictionary {
            let version = info["CFBundleShortVersionString"] as? String ?? "?"
            let build = info["CFBundleVersion"] as? String ?? "?"
            d["appVersion"] = "\(version) (\(build))"
        }

        // Device / iOS
        #if os(iOS)
        d["systemVersion"] = UIDevice.current.systemVersion
        d["device"] = UIDevice.current.model
        #endif

        // Auth
        if let user = Auth.auth().currentUser {
            d["uid"] = user.uid
            d["email"] = user.email ?? ""
            d["displayName"] = user.displayName ?? ""
        }

        // Timestamp (client-side; server adds one too)
        d["clientTime"] = ISO8601DateFormatter().string(from: Date())
        return d
    }
}