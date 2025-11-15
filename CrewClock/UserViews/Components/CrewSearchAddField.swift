//
//  CrewSearchAddField.swift
//  CrewClock
//
//  Created by Edgars Yarmolatiy on 10/8/25.
//

import SwiftUI
import FirebaseAuth

struct CrewSearchAddField: View {
    @EnvironmentObject private var userViewModel: UserViewModel
    @EnvironmentObject private var searchUserViewModel: SearchUserViewModel

    /// Entities to exclude from search (id -> "user" or "team")
    @Binding var exclude: [String: String]
    /// Unified selection: id -> "user" or "team"
    @Binding var selectedEntities: [String: String]
    @State private var crewSearch: String = ""
    let showAddedCrewList: Bool
    var allowMySelfSelection: Bool = false
    
    var body: some View {
        let userIDs = selectedEntities.filter { $0.value == "user" }.map { $0.key }
        let teamIDs = selectedEntities.filter { $0.value == "team" }.map { $0.key }
        crewSection(userIDs: userIDs, teamIDs: teamIDs)
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
    
    private func crewSection(userIDs: [String], teamIDs: [String]) -> some View {
        Section(header: Text("Crew")) {
            if !userIDs.isEmpty && showAddedCrewList { crewList(for: userIDs) }
            if !teamIDs.isEmpty && showAddedCrewList { teamList(for: teamIDs) }

            /// Allows to add myself to Array
            if allowMySelfSelection {
                meRow
            }

            TextField("Search to add crew", text: $crewSearch)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.search)
        }
    }

    /// Row for quickly adding/removing the current user to/from the crew.
    private var meRow: some View {
        // Prefer the user from UserViewModel; fall back to Auth if needed.
        let meUID = userViewModel.user?.uid ?? Auth.auth().currentUser?.uid
        
        return Group {
            if let meUID {
                Toggle("Add myself", isOn: Binding<Bool>(
                    get: {
                        selectedEntities[meUID] == "user"
                    },
                    set: { isOn in
                        if isOn {
                            selectedEntities[meUID] = "user"
                        } else {
                            selectedEntities.removeValue(forKey: meUID)
                        }
                    }
                ))
                .toggleStyle(.switch)
            }
        }
    }
    
    // MARK: Crew search results
    private var crewSearchingView: some View {
        let me = userViewModel.user?.uid
        let excludeSet = Set(exclude.keys)
        let results = searchUserViewModel.foundUIDs.filter { $0 != me && !excludeSet.contains($0) }
        return Group {
            if results.isEmpty {
                Text("No users found.").foregroundColor(.secondary)
            } else {
                ForEach(Array(results.enumerated()), id: \.element) { index, uid in
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

        return Group {
            if results.isEmpty {
                Text("No team found.").foregroundColor(.secondary)
            } else {
                ForEach(Array(results.enumerated()), id: \.element) { index, teamId in
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
            HStack(spacing: 10) {
                Button(action: { removeUserFromCrew(uid) }) {
                    Image(systemName: "minus.circle.fill")
                        .symbolRenderingMode(.multicolor)
                        .foregroundColor(.red)
                }
                .buttonStyle(.borderless)
                UserRowView(uid: uid)
            }
        }
    }

    private func teamList(for teamIDs: [String]) -> some View {
        ForEach(teamIDs, id: \.self) { teamId in
            HStack {
                Button(action: { removeTeamFromCrew(teamId) }) {
                    Image(systemName: "minus.circle.fill")
                        .symbolRenderingMode(.multicolor)
                        .foregroundColor(.red)
                }
                .buttonStyle(.borderless)
                TeamRowView(teamId: teamId)
            }
        }
    }

    private func removeTeamFromCrew(_ teamId: String) {
        selectedEntities.removeValue(forKey: teamId)
    }

    // Crew ops
    private func removeUserFromCrew(_ uid: String) {
        selectedEntities.removeValue(forKey: uid)
    }
}


#Preview {
    CrewSearchAddField(
        exclude: .constant([:]),
        selectedEntities: .constant([:]),
        showAddedCrewList: true
    )
    .environmentObject(UserViewModel())
    .environmentObject(SearchUserViewModel())
}
