import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct AddMembersView: View {
    @Environment(\.dismiss) private var dismiss
    
    let teamId: String
    let initialMembers: [String]
    let existingMembers: [TeamMemberEntry]
    let updateMembers: Bool = false
    let editing: Bool = false
    
    @StateObject var vmMembers = AddMembersToTeamViewModel()
    @StateObject private var vm = SearchUserViewModel()
    @State private var existingRoles: [String: TeamRole] = [:]
    @State private var selectedRoles: [String: TeamRole] = [:]
    @State private var selectedEntities: [String: String] = [:] // id -> "user" | "team"
    
    @EnvironmentObject private var userViewModel: UserViewModel
    @FocusState private var isSearchFocused: Bool
    
    @State var searchText = ""
    @State var errorMessage = ""
    
    var body: some View {
        list
            .navigationTitle("Add Members")
            .toolbar {
                if isSearchFocused {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button { isSearchFocused = false } label: { Text("Done") }
                    }
                }
            }
            .onAppear { onAppear() }
            .onChange(of: selectedEntities) { newValue in
                // mirror only user IDs into the dictionary this view expects
                vmMembers.members = newValue.reduce(into: [:]) { acc, pair in
                    if pair.value == "user" { acc[pair.key] = "user" }
                }
            }
    }
    
    private var list: some View {
        GlassList {
            searchSection
            membersSection
            if !errorMessage.isEmpty {
                Section {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                }
                .listSectionSpacing(10)
            }
            if !isSearchFocused {
                Section {
                    finishButton
                }
                .listSectionSpacing(10)
            }
        }
    }
    
    private var searchSection: some View {
        CrewSearchAddField(
            exclude: .constant(vmMembers.members),
            selectedEntities: $selectedEntities,
            showAddedCrewList: false
        )

    }
    
    private var membersSection: some View {
        Section {
            if !updateMembers {
                ownerRow
            }
            forEachMember
        } header: {
            Text("Members")
        }
        .onAppear {
            print("vmMembers.members in view \(vmMembers.members)")
        }
    }
    
    private var ownerRow: some View {
        HStack {
            if let currentUser = userViewModel.user {
                UserRowView(uid: currentUser.uid)
            } else {
                Text("You")
            }
            Spacer()
            Text("owner")
                .foregroundStyle(.secondary)
                .font(.caption)
        }
    }
    
    private var forEachMember: some View {
        let myUid = userViewModel.user?.uid ?? Auth.auth().currentUser?.uid
        let allUserIDs: [String] = vmMembers.members.filter { $0.value == "user" }.map { $0.key }
        let filtered: [String] = {
            if let myUid, !updateMembers {
                return allUserIDs.filter { $0 != myUid }
            } else {
                return allUserIDs
            }
        }()
        return Group {
            ForEach(filtered, id: \.self) { uid in
                memberRow(uid: uid)
            }
        }
    }

    @ViewBuilder
    private func memberRow(uid: String) -> some View {
        HStack {
            UserRowView(uid: uid)
            Spacer()
            if let role = existingRoles[uid] {
                existingRoleBadge(role)
            } else {
                rolePicker(for: uid)
            }
        }
    }

    private func existingRoleBadge(_ role: TeamRole) -> some View {
        Text(role.displayName)
            .font(.caption)
            .foregroundStyle(.secondary)
    }

    private func rolePicker(for uid: String) -> some View {
        // explicitly pull current selection out of the EnvironmentObject
        let currentRole: TeamRole = selectedRoles[uid] ?? .member

        return Menu {
            Picker("Role", selection: Binding<TeamRole>(
                get: { selectedRoles[uid] ?? .member },
                set: { newRole in selectedRoles[uid] = newRole }
            )) {
                ForEach(Array(TeamRole.allCases), id: \.rawValue) { role in
                    Text(role.displayName).tag(role)
                }
            }
        } label: {
            HStack(spacing: 4) {
                Text(currentRole.displayName)
                Image(systemName: "chevron.up.chevron.down")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .buttonStyle(.plain)
    }

    
    private var searchView: some View {
        TextField("Search for User", text: $searchText)
            .focused($isSearchFocused)
            .textInputAutocapitalization(.never)
            .disableAutocorrection(true)
            .submitLabel(.search)
            .onSubmit {
                let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
                var exclude = Set(vmMembers.members.keys)
                if let me = Auth.auth().currentUser?.uid { exclude.insert(me) }
                vm.searchUsers(with: q, alsoExclude: exclude)
            }
            .onChange(of: searchText) { oldVal, newVal in
                let q = newVal.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !q.isEmpty, q.count >= 1 else { vm.foundUIDs = []; return }
                var exclude = Set(vmMembers.members.keys)
                if let me = Auth.auth().currentUser?.uid { exclude.insert(me) }
                vm.searchUsers(with: q, alsoExclude: exclude)
            }
            .onReceive(vm.$foundUIDs) { ids in
                print("🔎 updated foundUIDs:", ids)
            }
    }
    
    private var searchResults: some View {
        Group {
            if vm.foundUIDs.isEmpty && !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text("No users found for “\(searchText)”")
                    .foregroundStyle(.secondary)
            } else {
                foundUsers
            }
        }
    }
    
    private var foundUsers: some View {
        ForEach(vm.foundUIDs, id: \.self) { uid in
            HStack {
                UserRowView(uid: uid)
                Spacer()
                Button {
                    if vmMembers.members[uid] == nil {
                        vmMembers.members[uid] = "user"
                    }
                    if existingRoles[uid] == nil && selectedRoles[uid] == nil {
                        selectedRoles[uid] = .member
                    }
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
    }
    
    private var finishButton: some View {
        Button {
            finish()
        } label: {
            Label(vmMembers.isSaving ? "Saving…" : "Finish", systemImage: "checkmark")
        }
        .padding(K.UI.padding)
        .frame(maxWidth: .infinity)
        .background(K.Colors.accent)
        .foregroundStyle(.white)
        .cornerRadius(K.UI.cornerRadius)
        .listRowInsets(EdgeInsets())
        .listRowBackground(Color.clear)
        .buttonStyle(.plain)
        .disabled(vmMembers.isSaving)
    }
    
    // MARK: Functions
    private func finish() {
        if vmMembers.members.isEmpty {
            errorMessage = "Add at least one member or tap Finish to continue."
            return
        }
        errorMessage = ""

        let senderName = userViewModel.user?.name
            ?? Auth.auth().currentUser?.displayName
            ?? "Someone"
        let senderUid  = userViewModel.user?.uid
            ?? Auth.auth().currentUser?.uid
            ?? ""

        Task {
            let ok = await vmMembers.saveMembersAndNotify(
                teamId: teamId,
                senderName: senderName,
                senderUid: senderUid
            )
            if ok { dismiss() /* or pop to root using the NavigationPath as discussed */ }
        }
    }
    
    private func onAppear() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            isSearchFocused = true
            // Preload initial members if provided and the VM is empty
            if vmMembers.members.isEmpty && !initialMembers.isEmpty {
                var preload: [String: String] = [:]
                for uid in initialMembers { preload[uid] = "user" }
                vmMembers.members = preload
            }
        }
        // Build role map from the members passed in
        let roleMap = Dictionary(uniqueKeysWithValues: existingMembers.map { ($0.uid, $0.role) })
        existingRoles = roleMap

        // Merge any preloaded members + initialMembers + existingMembers (uids)
        var mergedDict = vmMembers.members
        for uid in initialMembers { mergedDict[uid] = "user" }
        for entry in existingMembers { mergedDict[entry.uid] = "user" }
        vmMembers.members = mergedDict

        // Ensure default role choice for new (non-existing) members
        for uid in vmMembers.members.keys where existingRoles[uid] == nil {
            if selectedRoles[uid] == nil { selectedRoles[uid] = .member }
        }
        // Prefill selectedEntities with the current dictionary
        selectedEntities = vmMembers.members
    }
}

#Preview {
    NavigationStack {
        AddMembersView(
            teamId: "",
            initialMembers: [],
            existingMembers: [
                TeamMemberEntry(uid: "uid_1", role: .owner),
                TeamMemberEntry(uid: "uid_2", role: .admin),
                TeamMemberEntry(uid: "uid_3", role: .member)
            ]
        )
            .environmentObject(UserViewModel())
            .environmentObject(AddMembersToTeamViewModel())
    }
}
