//
//  AccountDeletionViewModel.swift
//  CrewClock
//
//  Created by Edgars Yarmolatiy on 8/14/25.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import GoogleSignIn

@MainActor
final class AccountDeletionViewModel: ObservableObject {
    enum Phase: Equatable {
        case idle
        case confirming      // after first button tap (confirmationDialog)
        case finalConfirm    // sheet with "type DELETE"
        case running         // deleting…
        case done
        case needsReauth     // Firebase requires recent login
        case error(String)
    }

    @Published var phase: Phase = .idle
    @Published var isWorking: Bool = false
    @Published var progress: String = ""
    @Published var confirmText: String = ""

    private let db = Firestore.firestore()

    // MARK: - Public entry
    func startFirstConfirmation() {
        phase = .confirming
    }

    func goToFinalConfirmation() {
        phase = .finalConfirm
    }

    func cancel() {
        confirmText = ""
        isWorking = false
        progress = ""
        phase = .idle
    }

    // MARK: - Main Orchestrator
    func permanentlyDeleteAccount() {
        guard confirmText.trimmingCharacters(in: .whitespacesAndNewlines).uppercased() == "DELETE" else {
            phase = .error("Please type DELETE to confirm.")
            return
        }
        Task { await runDeletion() }
    }

    // MARK: - Deletion steps
    private func setProgress(_ text: String) {
        progress = text
        // small haptic could be triggered by the View, if you want
    }

    private func uid() throws -> String {
        guard let uid = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "AccountDeletion", code: 0, userInfo: [NSLocalizedDescriptionKey: "No signed-in user"])
        }
        return uid
    }

    private func runDeletion() async {
        isWorking = true
        phase = .running

        do {
            let uid = try uid()

            // 1) Logs (two sources)
            setProgress("Deleting your logs…")
            try await deleteQueryInBatches(
                db.collection("logs").whereField("createdBy", isEqualTo: uid)
            )
            // Some of your logs may not have createdBy; also remove ones where you're in crewUID
            try await deleteQueryInBatches(
                db.collection("logs").whereField("crewUID", arrayContains: uid)
            )

            // logsForSheets
            setProgress("Deleting logs for sheets…")
            try await deleteQueryInBatches(
                db.collection("logsForSheets").whereField("createdBy", isEqualTo: uid)
            )

            // 2) Projects
            setProgress("Deleting your projects…")
            // Delete projects you OWN
            let owned = try await db.collection("projects").whereField("owner", isEqualTo: uid).getDocumentsAsync()
            for doc in owned.documents {
                // If you later add subcollections under projects (e.g., tasks/teams),
                // delete them here by name before removing the project doc.
                // Example:
                // try await deleteAllDocs(in: db.collection("projects").document(doc.documentID).collection("tasks"))
                try await doc.reference.deleteAsync()
            }

            // Projects where you're in crew → just remove you from crew array (do not nuke others' work)
            setProgress("Leaving projects where you’re a member…")
            let member = try await db.collection("projects").whereField("crew", arrayContains: uid).getDocumentsAsync()
            for doc in member.documents {
                try await doc.reference.updateDataAsync(["crew": FieldValue.arrayRemove([uid])])
            }

            // 3) Notifications (sent or received)
            setProgress("Cleaning up notifications…")
            try await deleteQueryInBatches(
                db.collection("notifications").whereField("fromUID", isEqualTo: uid)
            )
            try await deleteQueryInBatches(
                db.collection("notifications").whereField("recipientUID", arrayContains: uid)
            )

            // 3.5) Remove this UID from other users' connections
            setProgress("Removing connections from other users…")
            let connectedSnap = try await db.collection("users")
                .whereField("connections", arrayContains: uid)
                .getDocumentsAsync()

            // Batch in chunks to respect 500 writes per batch
            var refs = connectedSnap.documents.map { $0.reference }
            while !refs.isEmpty {
                let chunk = Array(refs.prefix(400))
                refs.removeFirst(chunk.count)

                let batch = db.batch()
                for ref in chunk {
                    batch.updateData(["connections": FieldValue.arrayRemove([uid])], forDocument: ref)
                }
                try await batch.commitAsync()
            }

            // 4) fcmTokens subcollection
            setProgress("Removing device tokens…")
            let fcmSnap = try await db.collection("users").document(uid).collection("fcmTokens").getDocumentsAsync()
            for f in fcmSnap.documents {
                try await f.reference.deleteAsync()
            }

            // 5) User profile document
            setProgress("Deleting your profile…")
            try await db.collection("users").document(uid).deleteAsync()

            // 6) Auth user (last)
            setProgress("Deleting your sign-in account…")
            do {
                try await Auth.auth().currentUser?.delete()
            } catch {
                // Most common: requires recent login
                if let err = error as NSError?, err.code == AuthErrorCode.requiresRecentLogin.rawValue {
                    phase = .needsReauth
                    isWorking = false
                    return
                } else {
                    throw error
                }
            }

            // 7) Local sign out (defensive)
            let authVM = AuthViewModel()
            // after successful delete (phase -> .done) do:
            DispatchQueue.main.async {
                authVM.signOut()   // sets isSignedIn = false; UI jumps to SignInView()
                NotificationCenter.default.post(name: .authDidSignOut, object: nil)
            }
            authVM.checkIfSignedIn()

            isWorking = false
            phase = .done
        } catch {
            isWorking = false
            phase = .error(error.localizedDescription)
        }
    }
    private func removeConnectionsFromOthers(myUID: String) async throws {
        setProgress("Removing connections from other users…")

        // Find all users who have you in their `connections`
        let snap = try await db.collection("users")
            .whereField("connections", arrayContains: myUID)
            .getDocumentsAsync()

        // Update in batches to avoid write limits
        var pending: [DocumentReference] = snap.documents.map(\.reference)

        while !pending.isEmpty {
            let chunk = Array(pending.prefix(400)) // Firestore allows 500 writes per batch; keep margin
            pending.removeFirst(chunk.count)

            let batch = db.batch()
            for ref in chunk {
                batch.updateData(["connections": FieldValue.arrayRemove([myUID])], forDocument: ref)
            }
            try await batch.commitAsync()
        }
    }

    // MARK: - Helpers (batched deletes + async niceties)
    private func deleteQueryInBatches(_ query: Query, batchSize: Int = 200) async throws {
        var lastBatchCount = 0
        repeat {
            let snapshot = try await query.limit(to: batchSize).getDocumentsAsync()
            lastBatchCount = snapshot.documents.count
            guard lastBatchCount > 0 else { break }

            let batch = db.batch()
            for doc in snapshot.documents {
                batch.deleteDocument(doc.reference)
            }
            try await batch.commitAsync()
        } while lastBatchCount == batchSize
    }
}

// MARK: - Small async wrappers
extension DocumentReference {
    func deleteAsync() async throws {
        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
            self.delete { err in
                if let err = err { cont.resume(throwing: err) } else { cont.resume() }
            }
        }
    }

    func updateDataAsync(_ data: [String: Any]) async throws {
        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
            self.updateData(data) { err in
                if let err = err { cont.resume(throwing: err) } else { cont.resume() }
            }
        }
    }
}

extension Query {
    func getDocumentsAsync() async throws -> QuerySnapshot {
        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<QuerySnapshot, Error>) in
            self.getDocuments { snap, err in
                if let err = err { cont.resume(throwing: err) }
                else if let snap = snap { cont.resume(returning: snap) }
            }
        }
    }
}

extension WriteBatch {
    func commitAsync() async throws {
        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
            self.commit { err in
                if let err = err { cont.resume(throwing: err) } else { cont.resume() }
            }
        }
    }
}
