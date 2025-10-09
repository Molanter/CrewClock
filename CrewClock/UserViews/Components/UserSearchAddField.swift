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

    @Binding var exclude: [String]
    @Binding var usersArray: [String]
    @State private var crewSearch: String = ""
    let showAddedCrewList: Bool
    
    var body: some View {
        crewSection
        // Debounced search driven from view-level task
        .task(id: crewSearch) {
            let q = crewSearch.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !q.isEmpty else {
                searchUserViewModel.foundUIDs = []
                return
            }
            try? await Task.sleep(nanoseconds: 300_000_000) // 300ms debounce
            if let me = Auth.auth().currentUser?.uid { exclude.append(me) }

            searchUserViewModel.searchUsers(with: q, alsoExclude: Set(exclude))
        }
    }
    
    private var crewSection: some View {
        Section(header: Text("Crew")) {
            if !usersArray.isEmpty && showAddedCrewList { crewList }

            TextField("Search to add crew", text: $crewSearch)
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)
                .submitLabel(.search)

            if !crewSearch.isEmpty {
                crewSearchingView
            }
        }
    }
    
    // MARK: Crew search results
    private var crewSearchingView: some View {
        let me = userViewModel.user?.uid
        let excludeSet = Set(exclude)
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
                            usersArray.append(uid)
                            print("User uid added: \(uid)")
                            print("Here is full array: \(usersArray)")
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    // MARK: Crew list
    private var crewList: some View {
        ForEach(usersArray, id: \.self) { uid in
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
        if let index = usersArray.firstIndex(of: uid) {
            usersArray.remove(at: index)
        }
    }
}

#Preview {
    UserSearchAddField(
        exclude: .constant([]),
        usersArray: .constant([]),
        showAddedCrewList: true
    )
    .environmentObject(UserViewModel())
    .environmentObject(SearchUserViewModel())
}
