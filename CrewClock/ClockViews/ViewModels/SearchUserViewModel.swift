//
//  SearchUserViewModel.swift
//  CrewClock
//
//  Created by Edgars Yarmolatiy on 7/20/25.
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth

class SearchUserViewModel: ObservableObject {
    @Published var foundUIDs: [String] = []

    func searchUsers(with query: String, alsoExclude exclude: Set<String> = []) {
        Task {
            let ids = await findUserIDs(query: query, excludeUIDs: exclude)
            await MainActor.run {
                self.foundUIDs = ids
            }
        }
    }
    
    private func prefixIDs(
        in col: CollectionReference,
        field: String,
        prefix: String,
        limit: Int
    ) async throws -> [String] {
        let end = prefix + "\u{f8ff}"
        let snap = try await col.whereField(field, isGreaterThanOrEqualTo: prefix)
                                .whereField(field, isLessThanOrEqualTo: end)
                                .limit(to: limit)
                                .getDocuments()
        return snap.documents.map { $0.documentID }
    }
    
    func findUserIDs(
        query: String,
        nameLimit: Int = 2,
        emailLimit: Int = 3,
        excludeUIDs: Set<String> = []
    ) async -> [String] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return [] }

        let db = Firestore.firestore()
        let col = db.collection("users")

        // Build the searches you want to run in parallel
        async let nameLower = try? prefixIDs(in: col, field: "name",  prefix: q,             limit: nameLimit)
        async let nameUpper = try? prefixIDs(in: col, field: "name",  prefix: q.capitalized, limit: nameLimit)
        async let emailPref = try? prefixIDs(in: col, field: "email", prefix: q,             limit: emailLimit)

        // Collect results
        let groups = [await nameLower, await nameUpper, await emailPref].compactMap { $0 }
        var ids = Set<String>()
        groups.forEach { ids.formUnion($0) }

        // Exclude current user + any extra UIDs
        if let me = Auth.auth().currentUser?.uid {
            ids.remove(me)
        }
        ids.subtract(excludeUIDs)

        return Array(ids)
    }

    private func searchByEmailFallback(_ currentUIDs: [String], query: String) {
        Firestore.firestore().collection("users")
            .whereField("email", isGreaterThanOrEqualTo: query.lowercased())
            .whereField("email", isLessThanOrEqualTo: query.lowercased() + "\u{f8ff}")
            .limit(to: 10)
            .getDocuments { snapshot, error in
                if let documents = snapshot?.documents {
                    let emailUIDs = documents.map { $0.documentID }
                    let combined = Array(Set(currentUIDs + emailUIDs))
                    self.foundUIDs = combined
                    print("searchUserViewModel.foundUIDs: -- ", self.foundUIDs)
                } else {
                    self.foundUIDs = currentUIDs
                }
            }
    }
    
    /// Search among your *accepted* connections by name or email (prefix, case-insensitive)
    func searchAcceptedConnections(matching query: String, limit: Int = 50) {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !q.isEmpty else {
            self.foundUIDs = []
            return
        }

        Task {
            guard let me = Auth.auth().currentUser?.uid else {
                await MainActor.run { self.foundUIDs = [] }
                return
            }
            let db = Firestore.firestore()

            do {
                // 1) Fetch all relationships that include me → filter to accepted locally (no index required)
                let relSnap = try await db.collection("connections")
                    .whereField("uids", arrayContains: me)
                    .getDocuments()

                // Collect OTHER user IDs for accepted connections
                var otherUIDs = Set<String>()
                for doc in relSnap.documents {
                    let d = doc.data()
                    let status = (d["status"] as? String ?? "").trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                    guard status == "accepted" else { continue }
                    if let uids = d["uids"] as? [String],
                       let other = uids.first(where: { $0 != me }) {
                        otherUIDs.insert(other)
                    }
                }

                guard !otherUIDs.isEmpty else {
                    await MainActor.run { self.foundUIDs = [] }
                    return
                }

                // 2) Fetch those user docs in batches of 10 (Firestore whereIn limit)
                var matched = [String]()
                let allIDs = Array(otherUIDs)
                let batches = stride(from: 0, to: allIDs.count, by: 10).map {
                    Array(allIDs[$0..<min($0+10, allIDs.count)])
                }

                for batch in batches {
                    let snap = try await db.collection("users")
                        .whereField(FieldPath.documentID(), in: batch)
                        .getDocuments()

                    for doc in snap.documents {
                        let d = doc.data()
                        // Prefer shadow fields if you maintain them; else fall back
                        let nameLower  = (d["name"]  as? String)?.lowercased()  ?? ""
                        let emailLower = (d["email"] as? String)?.lowercased() ?? ""

                        // Prefix match on name OR email
                        if nameLower.hasPrefix(q) || emailLower.hasPrefix(q) {
                            matched.append(doc.documentID)
                            if matched.count >= limit { break }
                        }
                    }
                    if matched.count >= limit { break }
                }

                await MainActor.run { self.foundUIDs = matched }
            } catch {
                print("❌ searchAcceptedConnections error: \(error.localizedDescription)")
                await MainActor.run { self.foundUIDs = [] }
            }
        }
    }
}
