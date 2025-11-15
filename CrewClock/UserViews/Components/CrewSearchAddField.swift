//
//  CrewSearchAddField.swift
//  CrewClock
//
//  Created by Edgars Yarmolatiy on 10/8/25.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct CrewSearchAddField: View {
    @EnvironmentObject private var userViewModel: UserViewModel
    @EnvironmentObject private var searchUserViewModel: SearchUserViewModel

    /// User IDs to exclude from search (already added, etc.)
    @Binding var excludeUIDs: [String]
    /// Unified selection: list of selected user IDs
    @Binding var selectedUIDs: [String]
    @State private var crewSearch: String = ""
    let showAddedCrewList: Bool
    var allowMySelfSelection: Bool = false
    
    var body: some View {
        let userIDs = selectedUIDs
        crewSection(userIDs: userIDs)
        // Debounced search driven from view-level task
        .task(id: crewSearch) {
            let q = crewSearch.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !q.isEmpty else {
                searchUserViewModel.foundUIDs = []
                return
            }
            try? await Task.sleep(nanoseconds: 300_000_000) // 300ms debounce

            var excludeUserIDs = Set(excludeUIDs)
            if let me = Auth.auth().currentUser?.uid {
                excludeUserIDs.insert(me)
            }

            searchUserViewModel.searchUsers(with: q, alsoExclude: excludeUserIDs)
            await searchUserViewModel.searchTeams(with: q, excludeTeamIDs: [])
        }
    }
    
    private func crewSection(userIDs: [String]) -> some View {
        Section(header: Text("Crew")) {
            if !userIDs.isEmpty && showAddedCrewList { crewList(for: userIDs) }

            /// Allows to add myself to Array
            if allowMySelfSelection {
                meRow
            }

            TextField("Search to add crew", text: $crewSearch)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.search)

            // Show search results when there is a non-empty query
            let query = crewSearch.trimmingCharacters(in: .whitespacesAndNewlines)
            if !query.isEmpty {
                crewSearchingView
                teamSearchingView
            }
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
                        selectedUIDs.contains(meUID)
                    },
                    set: { isOn in
                        if isOn {
                            if !selectedUIDs.contains(meUID) {
                                selectedUIDs.append(meUID)
                            }
                        } else {
                            selectedUIDs.removeAll { $0 == meUID }
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
        let excludeSet = Set(excludeUIDs)
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
                            if !selectedUIDs.contains(uid) {
                                selectedUIDs.append(uid)
                            }
                            print("User uid added: \(uid)")
                            print("Selections:", selectedUIDs)
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

        return Group {
            if results.isEmpty {
                Text("No team found.").foregroundColor(.secondary)
            } else {
                ForEach(Array(results.enumerated()), id: \.element) { index, teamId in
                    HStack {
                        TeamRowView(teamId: teamId)
                        Spacer()
                        Button("Add") {
                            Task { @MainActor in
                                await addTeamAsExpandedUsers(teamId)
                            }
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

    /// Treats a team as a saved group and adds its members as individual user selections.
    /// Loads members from Firestore at `teams/{teamId}/members` and appends their UIDs.
    @MainActor
    private func addTeamAsExpandedUsers(_ teamId: String) async {
        // Clear the search field so the user sees the updated crew list.
        crewSearch = ""

        do {
            let db = Firestore.firestore()
            // Fetch all members of this team
            let snapshot = try await db
                .collection("teams")
                .document(teamId)
                .collection("members")
                .getDocuments()

            let rawMemberUIDs: [String] = snapshot.documents.compactMap { doc in
                // Prefer explicit uid field; fall back to documentID if needed.
                if let uid = doc.data()["uid"] as? String {
                    return uid
                } else {
                    return doc.documentID
                }
            }

            if rawMemberUIDs.isEmpty {
                print("⚠️ No member documents found for team \(teamId)")
            }

            // Never add myself when expanding a team
            let meUID = userViewModel.user?.uid ?? Auth.auth().currentUser?.uid
            let memberUIDs = rawMemberUIDs.filter { uid in
                if let meUID { return uid != meUID }
                return true
            }

            // Append each member UID individually to the crew selection
            for uid in memberUIDs {
                if !selectedUIDs.contains(uid) {
                    selectedUIDs.append(uid)
                }
            }
        } catch {
            print("⚠️ Failed to expand team \(teamId) into members: \(error)")
        }
    }

    // Crew ops
    private func removeUserFromCrew(_ uid: String) {
        selectedUIDs.removeAll { $0 == uid }
    }
}


#Preview {
    CrewSearchAddField(
        excludeUIDs: .constant([]),
        selectedUIDs: .constant([]),
        showAddedCrewList: true
    )
    .environmentObject(UserViewModel())
    .environmentObject(SearchUserViewModel())
}
