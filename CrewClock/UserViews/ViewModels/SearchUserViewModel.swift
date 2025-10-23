import SwiftUI
import FirebaseFirestore
import FirebaseAuth

class SearchUserViewModel: ObservableObject {
    @Published var searchText = ""
    @Published var foundUIDs: [String] = []
    @Published var foundTeamIDs: [String] = []
    @Published var lastError: String?

    private let db = Firestore.firestore()
    private var usersCol: CollectionReference { db.collection("users") }

    /// Public entry: search by name OR email, returns up to 6 UIDs.
    func searchUsers(with query: String, alsoExclude exclude: Set<String> = []) {
        Task {
            let ids = await findUserIDs(query: query, excludeUIDs: exclude, totalLimit: 6)
            await MainActor.run { self.foundUIDs = ids }
        }
    }

    /// Search teams the current user belongs to (member/admin/owner), filter by name prefix.
    /// Uses collectionGroup("members") to find memberships, then loads team docs and filters by name.
    @MainActor
    func searchTeams(with query: String, excludeTeamIDs: Set<String> = []) async {
        let raw = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !raw.isEmpty, let uid = Auth.auth().currentUser?.uid else {
            self.foundTeamIDs = []
            return
        }
        let q = raw.lowercased()
        do {
            // 1) Find team memberships via collection group
            let memberSnaps = try await db.collectionGroup("members")
                .whereField("uid", isEqualTo: uid)
                .getDocuments()

            let teamIds = Set(memberSnaps.documents.map { $0.reference.parent.parent?.documentID ?? "" }.filter { !$0.isEmpty })

            if teamIds.isEmpty {
                self.foundTeamIDs = []
                return
            }

            // 2) Load teams and filter by nameLower (preferred) or name
            var matched: [String] = []
            for tid in teamIds {
                guard !excludeTeamIDs.contains(tid) else { continue }
                let tdoc = try await db.collection("teams").document(tid).getDocument()
                guard let data = tdoc.data() else { continue }
                let name = (data["name"] as? String) ?? ""
                let nameLower = (data["nameLower"] as? String) ?? name.lowercased()
                if nameLower.hasPrefix(q) {
                    matched.append(tid)
                }
            }

            self.foundTeamIDs = Array(matched.prefix(8))
        } catch {
            await MainActor.run { self.lastError = error.localizedDescription; self.foundTeamIDs = [] }
        }
    }

    // MARK: - Core search (name + email, max `totalLimit`)
    func findUserIDs(
        query: String,
        excludeUIDs: Set<String> = [],
        totalLimit: Int = 6
    ) async -> [String] {
        let raw = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !raw.isEmpty else { return [] }
        let q = raw.lowercased()

        // 1) Try shadow fields (fast, case-insensitive)
        do {
            let nameL  = try await prefixIDs(field: "nameLower",  prefix: q, limit: totalLimit)
            let emailL = try await prefixIDs(field: "emailLower", prefix: q, limit: totalLimit)

            // Prioritize name matches, then fill with email until we reach totalLimit
            var ordered = orderedUnion(primary: nameL, secondary: emailL, limit: totalLimit)
            ordered = filterExclusions(ordered, excludeUIDs: excludeUIDs)
            if !ordered.isEmpty { return Array(ordered.prefix(totalLimit)) }
        } catch {
            await MainActor.run { self.lastError = error.localizedDescription }
        }

        // 2) Fallback to case-sensitive fields if shadow fields not present
        do {
            let candidates = Array(Set([
                raw, q, raw.capitalized,
                raw.prefix(1).uppercased() + q.dropFirst()
            ]))

            var nameHits = Set<String>()
            var emailHits = Set<String>()
            for key in candidates {
                nameHits.formUnion(try await prefixIDs(field: "name",  prefix: key, limit: totalLimit))
                emailHits.formUnion(try await prefixIDs(field: "email", prefix: key, limit: totalLimit))
            }

            var ordered = orderedUnion(primary: Array(nameHits), secondary: Array(emailHits), limit: totalLimit)
            ordered = filterExclusions(ordered, excludeUIDs: excludeUIDs)
            return Array(ordered.prefix(totalLimit))
        } catch {
            await MainActor.run { self.lastError = error.localizedDescription }
            return []
        }
    }

    // MARK: - Helpers

    private func prefixIDs(field: String, prefix: String, limit: Int) async throws -> [String] {
        let end = prefix + "\u{f8ff}"
        let snap = try await usersCol
            .whereField(field, isGreaterThanOrEqualTo: prefix)
            .whereField(field, isLessThanOrEqualTo: end)
            .limit(to: limit)
            .getDocuments()
        return snap.documents.map { $0.documentID }
    }

    /// Keep order: all primary first (unique), then secondary (unique) until limit.
    private func orderedUnion(primary: [String], secondary: [String], limit: Int) -> [String] {
        var seen = Set<String>()
        var out: [String] = []
        for id in primary where !seen.contains(id) {
            out.append(id); seen.insert(id)
            if out.count >= limit { return out }
        }
        for id in secondary where !seen.contains(id) {
            out.append(id); seen.insert(id)
            if out.count >= limit { return out }
        }
        return out
    }

    private func filterExclusions(_ list: [String], excludeUIDs: Set<String>) -> [String] {
        let me = Auth.auth().currentUser?.uid
        return list.filter { id in
            if let me, id == me { return false }
            return !excludeUIDs.contains(id)
        }
    }
}
