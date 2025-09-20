//
//  CreateTeamView.swift
//  CrewClock
//
//  Created by Edgars Yarmolatiy on 9/16/25.
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth

private struct NavTeam: Identifiable, Hashable {
    let id: String
}

struct CreateTeamView: View {
    @StateObject private var vm = CreateTeamViewModel()

    @Environment(\.presentationMode) var presentationMode
    
    @FocusState private var isNameFocused: Bool
    @State private var navTarget: NavTeam? = nil   // << programmatic push target

    var body: some View {
        list
            .navigationBarTitle("Create Team")
            .navigationDestination(item: $navTarget) { target in
                AddMembersView(teamId: target.id)
                    .onDisappear {
                        presentationMode.wrappedValue.dismiss()
                    }
            }
    }
    
    private var list: some View {
        GlassList {
            Section {
                nameTextField
            } header: {
                Text("Name Your Team")
            }
            if !isNameFocused {
                Section {
                    button
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                }
                .listSectionSpacing(15)
            }
        }
    }
    
    private var nameTextField: some View {
        TextField("Team Name", text: $vm.teamName)
            .focused($isNameFocused)
            .textInputAutocapitalization(.words)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if isNameFocused {
                        Button("Create") { create() }
                    }
                }
            }
    }

    private var button: some View {
        Button(action: create) {
            Label(vm.isCreating ? "Creating…" : "Create Team", systemImage: "arrow.right")
        }
        .disabled(vm.isCreating)
        .buttonStyle(.plain)
        .padding(K.UI.padding)
        .frame(maxWidth: .infinity)
        .background(K.Colors.accent)
        .cornerRadius(K.UI.cornerRadius)
    }
    
    
//MARK: Functions
    
    private func create() {
        Task {
            if let teamId = await vm.createTeam() {
                isNameFocused = false
                // Push to AddMembersView using parent NavigationStack
                navTarget = NavTeam(id: teamId)
            }
        }
    }
}

#Preview {
    CreateTeamView()
}
