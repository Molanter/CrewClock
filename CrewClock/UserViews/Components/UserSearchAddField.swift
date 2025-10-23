//
//  UserSearchAddField.swift
//  CrewClock
//
//  Created by Edgars Yarmolatiy on 10/8/25.
//

import SwiftUI
import FirebaseAuth

struct UserSearchAddField: View {
    @EnvironmentObject private var userViewModel: UserViewModel
    @EnvironmentObject private var searchUserViewModel: SearchUserViewModel

    /// Entities to exclude from search (id -> "user" or "team")
    @Binding var exclude: [String: String]
    /// Unified selection: id -> "user" or "team"
    @Binding var selectedEntities: [String: String]
    @State private var crewSearch: String = ""
    let showAddedCrewList: Bool
    
    var body: some View {
        let userIDs = selectedEntities.filter { $0.value == "user" }.map { $0.key }
        crewSection(userIDs: userIDs)
        // Debounced search driven from view-level task
        .task(id: crewSearch) {
            let q = crewSearch.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !q.isEmpty else {
                searchUserViewModel.foundUIDs = []
                return
            }
            try? await Task.sleep(nanoseconds: 300_000_000) // 300ms debounce
            if let me = Auth.auth().currentUser?.uid { exclude[me] = "user" }

            let excludeUserIDs = Set(exclude.filter { $0.value == "user" }.keys)
            let excludeTeamIDs = Set(exclude.filter { $0.value == "team" }.keys)
            searchUserViewModel.searchUsers(with: q, alsoExclude: excludeUserIDs)
            await searchUserViewModel.searchTeams(with: q, excludeTeamIDs: excludeTeamIDs)
        }
    }
    
    private func crewSection(userIDs: [String]) -> some View {
        Section(header: Text("Crew")) {
            if !userIDs.isEmpty && showAddedCrewList { crewList(for: userIDs) }

            TextField("Search to add crew", text: $crewSearch)
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)
                .submitLabel(.search)

            if !crewSearch.isEmpty {
                crewSearchingView
            }
            if !crewSearch.isEmpty {
                teamSearchingView
            }
        }
    }
    
    // MARK: Crew search results
    private var crewSearchingView: some View {
        let me = userViewModel.user?.uid
        let excludeSet = Set(exclude.keys)
        let results = searchUserViewModel.foundUIDs.filter { $0 != me && !excludeSet.contains($0) }

        return VStack(alignment: .leading) {
            if results.isEmpty {
                Text("No users found.").foregroundColor(.secondary)
            } else {
                ForEach(results, id: \.self) { uid in
                    HStack {
                        UserRowView(uid: uid)
                        Spacer()
                        Button("Add") {
                            crewSearch = ""
                            selectedEntities[uid] = "user"
                            print("User uid added: \(uid)")
                            print("Selections:", selectedEntities)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    // MARK: Team search results
    private var teamSearchingView: some View {
        let results = searchUserViewModel.foundTeamIDs
            .filter { !selectedEntities.keys.contains($0) } // avoid duplicates

        return VStack(alignment: .leading, spacing: 8) {
            if results.isEmpty {
                EmptyView()
            } else {
                ForEach(results, id: \.self) { teamId in
                    HStack {
                        TeamRowView(teamId: teamId)
                        Spacer()
                        Button("Add") {
                            crewSearch = ""
                            selectedEntities[teamId] = "team"
                            print("Team added:", teamId)
                            print("Selections:", selectedEntities)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    // MARK: Crew list
    private func crewList(for userIDs: [String]) -> some View {
        ForEach(userIDs, id: \.self) { uid in
            HStack {
                Button(action: { removeUserFromCrew(uid) }) {
                    Image(systemName: "minus.circle.fill")
                        .symbolRenderingMode(.multicolor)
                        .foregroundColor(.red)
                }
                UserRowView(uid: uid)
            }
        }
    }

    // Crew ops
    private func removeUserFromCrew(_ uid: String) {
        selectedEntities.removeValue(forKey: uid)
    }
}


#Preview {
    UserSearchAddField(
        exclude: .constant([:]),
        selectedEntities: .constant([:]),
        showAddedCrewList: true
    )
    .environmentObject(UserViewModel())
    .environmentObject(SearchUserViewModel())
}
