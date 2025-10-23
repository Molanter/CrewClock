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

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .imageScale(.large)
            VStack(alignment: .leading, spacing: 2) {
                Text(name).font(.body)
                Text("Team").font(.caption).foregroundColor(.secondary)
            }
        }
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
            }
        } catch {
            // Keep defaults on error
        }
        isLoading = false
    }
}
