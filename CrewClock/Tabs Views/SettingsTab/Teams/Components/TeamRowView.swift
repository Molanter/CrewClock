//
//  TeamRowView.swift
//  CrewClock
//
//  Created by Edgars Yarmolatiy on 10/22/25.
//

import SwiftUI
import FirebaseFirestore

struct TeamRowView: View {
    let teamId: String
    @State private var name: String = "Team"
    @State private var icon: String = "person.3"
    @State private var color: Color = K.Colors.accent
    @State private var isLoading = true
    @State private var memberCount: Int? = nil

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .foregroundStyle(color)
                .frame(width: 40, height: 40)
            VStack(alignment: .leading, spacing: 2) {
                Text(name).font(.body)
                if let memberCount {
                    Text("Team • \(memberCount) member\(memberCount == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    Text("Team")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .task {
            await loadTeam()
        }
    }

    private func loadTeam() async {
        do {
            let doc = try await FSPath.Team(id: teamId).doc(in: Firestore.firestore()).getDocument()
            if let data = doc.data() {
                if let n = data["name"] as? String { name = n }
                if let img = data["image"] as? String, !img.isEmpty { icon = img }
                color = Color(from: data["color"]) ?? K.Colors.accent

                // Fetch members count via aggregation (cheap and fast)
                let membersRef = Firestore.firestore()
                    .collection("teams")
                    .document(teamId)
                    .collection("members")
                do {
                    let agg = try await membersRef.count.getAggregation(source: .server)
                    memberCount = Int(agg.count)
                } catch {
                    // If aggregation is unsupported or fails, fall back to documents fetch (avoid in hot paths)
                    do {
                        let docs = try await membersRef.limit(to: 1_000).getDocuments()
                        memberCount = docs.count
                    } catch {
                        // leave memberCount nil
                    }
                }
            }
        } catch {
            // Keep defaults on error
        }
        isLoading = false
    }
}
