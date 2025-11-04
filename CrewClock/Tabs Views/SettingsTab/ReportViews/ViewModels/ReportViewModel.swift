//
//  ReportViewModel.swift
//  CrewClock
//
//  Created by Edgars Yarmolatiy on 11/3/25.
//

import Foundation
import SwiftUI
import FirebaseAuth
import FirebaseFirestore

enum ReportTarget: String, CaseIterable, Identifiable, Codable {
    case user, team, task, project, post, notification
    var id: String { rawValue }
    var label: String { rawValue.capitalized }
}

enum ReportSeverity: String, CaseIterable, Identifiable, Codable {
    case minor, normal, major, critical
    var id: String { rawValue }
    var label: String {
        switch self {
        case .minor: return "Minor"
        case .normal: return "Normal"
        case .major: return "Major"
        case .critical: return "Critical"
        }
    }
}

struct ReportPayload: Codable {
    var createdAt: Date
    var reporterUid: String?
    var reporterEmail: String?
    var reporterDisplayName: String?
    var shareContact: Bool

    var targetType: ReportTarget
    var targetRefId: String?
    var title: String
    var description: String
    var severity: ReportSeverity

    // Useful context for triage
    var appVersion: String?
    var appBuild: String?
    var osVersion: String?
    var deviceModel: String?
}

@MainActor
final class ReportViewModel: ObservableObject {
    // Form state
    @Published var targetType: ReportTarget = .task
    @Published var severity: ReportSeverity = .normal
    @Published var title: String = ""
    @Published var targetRefId: String = ""
    @Published var descriptionText: String = ""
    @Published var shareContact: Bool = true

    // UI state
    @Published var isSubmitting = false
    @Published var submitError: String?
    @Published var submitSuccess = false

    private let db = Firestore.firestore()

    var isValid: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !descriptionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func submit() async {
        guard isValid else {
            submitError = "Title and description are required."
            return
        }
        submitError = nil
        submitSuccess = false
        isSubmitting = true
        defer { isSubmitting = false }

        // Auth context
        let user = Auth.auth().currentUser

        // App + device context
        let bundle = Bundle.main
        let version = bundle.infoDictionary?["CFBundleShortVersionString"] as? String
        let build = bundle.infoDictionary?["CFBundleVersion"] as? String
        let osVersion = ProcessInfo.processInfo.operatingSystemVersionString
        #if os(iOS)
        let deviceModel = UIDevice.current.model
        #else
        let deviceModel = "Unknown"
        #endif

        let payload = ReportPayload(
            createdAt: Date(),
            reporterUid: user?.uid,
            reporterEmail: user?.email,
            reporterDisplayName: user?.displayName,
            shareContact: shareContact,
            targetType: targetType,
            targetRefId: targetRefId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : targetRefId,
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            description: descriptionText.trimmingCharacters(in: .whitespacesAndNewlines),
            severity: severity,
            appVersion: version,
            appBuild: build,
            osVersion: osVersion,
            deviceModel: deviceModel
        )

        do {
            let data = try JSONEncoder().encode(payload)
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]

            // Write to a top-level "reports" collection.
            // You can add security rules to restrict who can read.
            _ = try await db.collection("reports").addDocument(data: json)

            submitSuccess = true
            // Reset minimal fields; keep type to allow fast multiple reports.
            title = ""
            targetRefId = ""
            descriptionText = ""
            severity = .normal
        } catch {
            submitError = error.localizedDescription
        }
    }
}
