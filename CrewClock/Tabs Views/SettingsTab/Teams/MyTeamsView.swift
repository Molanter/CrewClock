//
//  MyTeamsView.swift
//  CrewClock
//
//  Created by Edgars Yarmolatiy on 9/18/25.
//

import SwiftUI

struct MyTeamsView: View {
    @EnvironmentObject private var projectViewModel: ProjectViewModel

    @StateObject private var vm = MyTeamsViewModel()
    @StateObject private var invitesVM = TeamInvitesViewModel()

    @State private var showOwned = true
    @State private var showMember = true

    // Context menu + confirmation dialog
    @State private var confirmDialogPresented = false
    @State private var actionForTeam: PendingAction?
    @State private var selectedTeam: TeamFB?

    enum PendingAction {
        case deleteTeam
        case leaveTeam
    }
    
    var body: some View {
        list
    }

    private var list: some View {
        GlassList {
            if vm.isLoading {
                Section { ProgressView().frame(maxWidth: .infinity) }
            }
            if !vm.errorMessage.isEmpty {
                Section { Text(vm.errorMessage).foregroundStyle(.red) }
            }
            ownedSection  /// Owned
            
            memberOfSection /// Member of team
            
            invitesSection /// Invites (always at bottom)
        }
        .navigationTitle("My Teams")
        .toolbar { toolbar }
        .onAppear { vm.start() }
        .confirmationDialog(
            dialogTitle(),
            isPresented: $confirmDialogPresented,
            titleVisibility: .visible
        ) {
            confirmLeaveAlert
        }
    }
    
    private var ownedSection: some View {
        Section {
            DisclosureGroup(isExpanded: $showOwned) {
                if vm.owned.isEmpty {
                    Text("No teams yet.").foregroundStyle(.secondary)
                } else {
                    ForEach(vm.owned) { team in
                        row(team)
                            .contextMenu { contextMenu(for: team) }
                    }
                }
            } label: {
                HStack {
                    Text("Owned by me")
                    Spacer()
                    Text("\(vm.owned.count)").foregroundStyle(.secondary)
                }
            }
        }
    }
    
    private var memberOfSection: some View {
        Section {
            DisclosureGroup(isExpanded: $showMember) {
                if vm.memberOf.isEmpty {
                    Text("No teams joined yet.").foregroundStyle(.secondary)
                } else {
                    ForEach(vm.memberOf) { team in
                        row(team)
                            .contextMenu { contextMenu(for: team) }
                    }
                }
            } label: {
                HStack {
                    Text("I’m a member")
                    Spacer()
                    Text("\(vm.memberOf.count)").foregroundStyle(.secondary)
                }
            }
        }
    }

    private var invitesSection: some View {
        Group {
            if !vm.invites.isEmpty {
                Section {
                    ForEach(vm.invites) { team in
                        inviteRow(team)
                    }
                } header: {
                    Text("Invites")
                } footer: {
                    Text("These teams have invited you. Accept to join or decline to ignore.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
    
    private var confirmLeaveAlert: some View {
        Group {
            if let action = actionForTeam, let team = selectedTeam {
                switch action {
                case .deleteTeam:
                    Button("Delete Team", role: .destructive) {
                        vm.deleteTeam(teamId: team.id)
                    }
                case .leaveTeam:
                    Button("Leave Team", role: .destructive) {
                        vm.leaveTeam(teamId: team.id)
                    }
                }
            }
            Button("Cancel", role: .cancel) { }
        }
    }
    
    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button { vm.start() } label: { Image(systemName: "arrow.clockwise") }
        }
        
        ToolbarItem(placement: .bottomBar) {
            NavigationLink {
                CreateTeamView()
            }label: {
                Image(systemName: "person.2.badge.plus")
            }
        }
    }
    // MARK: - Rows

    @ViewBuilder
    private func row(_ team: TeamFB) -> some View {
        NavigationLink {
            ManageTeamView(team: team)
                .hideTabBarWhileActive("active")
        } label: {
            HStack {
                imageRowGroup(team)
                VStack(alignment: .leading, spacing: 2) {
                    Text(team.name).font(.body)
                    Text("\(team.memberCount) member\(team.memberCount == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
    
    @ViewBuilder
    private func imageRowGroup(_ team: TeamFB) -> some View {
        Image(systemName: team.image)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 35, height: 35)
            .foregroundStyle(team.color)
    }

    @ViewBuilder
    private func inviteRow(_ team: TeamFB) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(team.name).font(.body)
                Text("Invite received")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                Task { await invitesVM.acceptInvite(teamId: team.id) }
            } label: {
                Text("Accept")
            }
            .buttonStyle(.borderedProminent)

            Button(role: .destructive) {
                vm.leaveTeam(teamId: team.id)
            } label: {
                Text("Decline")
            }
            .buttonStyle(.bordered)
        }
    }

    // MARK: - Context Menu

    @ViewBuilder
    private func contextMenu(for team: TeamFB) -> some View {
        if vm.isOwner(of: team) {
            Button(role: .destructive) {
                selectedTeam = team
                actionForTeam = .deleteTeam
                confirmDialogPresented = true
            } label: {
                Label("Delete Team…", systemImage: "trash")
            }
        } else {
            Button(role: .destructive) {
                selectedTeam = team
                actionForTeam = .leaveTeam
                confirmDialogPresented = true
            } label: {
                Label("Leave Team…", systemImage: "rectangle.portrait.and.arrow.right")
            }
        }
    }

    private func dialogTitle() -> String {
        guard let action = actionForTeam, let team = selectedTeam else { return "" }
        switch action {
        case .deleteTeam: return "Delete “\(team.name)”?"
        case .leaveTeam:  return "Leave “\(team.name)”?"
        }
    }
}
