import SwiftUI
import FirebaseFirestore
import FirebaseAuth

actor Debouncer {
    private var task: Task<Void, Never>?
    func schedule(after seconds: Double, _ action: @escaping @Sendable @MainActor () -> Void) {
        task?.cancel()
        task = Task {
            try? await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
            if Task.isCancelled { return }
            await action()
        }
    }
    func cancel() { task?.cancel() }
}

struct AddMembersView: View {
    @Environment(\.dismiss) private var dismiss
    
    let teamId: String
    
    @StateObject private var vmMembers = AddMembersViewModel()
    @StateObject private var vm = SearchUserViewModel()
    
    @EnvironmentObject private var userViewModel: UserViewModel
    @FocusState private var isSearchFocused: Bool
    
    @State var searchText = ""
    @State var errorMessage = ""
    @State private var debouncer = Debouncer()
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
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    isSearchFocused = true
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
        Section {
            searchView
            if !searchText.isEmpty {
                searchResults
            }
        } header: {
            Text("Search to Add User")
        }
    }
    
    private var membersSection: some View {
        Section {
            ownerRow
            forEachMember
        } header: {
            Text("Members")
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
        ForEach(vmMembers.members, id: \.self) { uid in
            HStack {
                UserRowView(uid: uid)
                Spacer()
                Text("member")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    private var searchView: some View {
        TextField("Search for User", text: $searchText)
            .focused($isSearchFocused)
            .textInputAutocapitalization(.never)
            .disableAutocorrection(true)
            .submitLabel(.search)
            .onSubmit {
                let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
                var exclude = Set(vmMembers.members)
                if let me = Auth.auth().currentUser?.uid { exclude.insert(me) }
                vm.searchUsers(with: q, alsoExclude: exclude)
            }
            .onChange(of: searchText) { oldVal, newVal in
                let q = newVal.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !q.isEmpty, q.count >= 1 else { vm.foundUIDs = []; return }
                var exclude = Set(vmMembers.members)
                if let me = Auth.auth().currentUser?.uid { exclude.insert(me) }
                vm.searchUsers(with: q, alsoExclude: exclude)
            }
            .onReceive(vm.$foundUIDs) { ids in
                print("🔎 updated foundUIDs:", ids)
            }
            .onReceive(vm.$foundUIDs) { ids in
                // This fires when the async search finishes and publishes
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
        ForEach(vm.foundUIDs.prefix(6), id: \.self) { uid in
            HStack {
                UserRowView(uid: uid)
                Spacer()
                Button {
                    if !vmMembers.members.contains(uid) {
                        vmMembers.members.append(uid)
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
}

#Preview {
    NavigationStack {
        AddMembersView(teamId: "")
            .environmentObject(UserViewModel())
    }
}
