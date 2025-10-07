//
//  ManageTeamView.swift
//  CrewClock
//
//  Created by Edgars Yarmolatiy on 9/24/25.
//

import SwiftUI

struct ManageTeamView: View {
    @EnvironmentObject private var userViewModel: UserViewModel

    @StateObject private var teamsVM = MyTeamsViewModel()
    @StateObject private var vmMembers = AddMembersViewModel()

    let team: TeamFB
    
    @State private var roleErrorMessage = ""
    @State private var showRoleActionSheet = false
    
    private let headerHeight: CGFloat = 200
    private var canManageMembers: Bool {
        let uid = userViewModel.user?.uid
        return team.members.contains { entry in
            entry.uid == uid && (entry.role == .owner || entry.role == .admin)
        }
    }

    private var sortedMembers: [TeamMemberEntry] {
        team.members.sorted { lhs, rhs in
            switch (lhs.role, rhs.role) {
            case (.owner, .owner), (.admin, .admin), (.member, .member):
                return lhs.uid < rhs.uid
            case (.owner, _):
                return true
            case (_, .owner):
                return false
            case (.admin, _):
                return true
            case (_, .admin):
                return false
            default:
                return lhs.uid < rhs.uid
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            list
                .toolbar {
                    if canManageMembers {
                        NavigationLink {
                            AddMembersView(teamId: team.id, initialMembers: team.members.map { $0.uid }, existingMembers: team.members)
                                .environmentObject(vmMembers)
                        } label: {
                            Label("Add members", systemImage: "person.badge.plus")
                        }
                    }
                }
        }
    }
    
    private var list: some View {
        GeometryReader { gr in
            GlassList {

                Section(header:
                            StretchyHeader(color: team.color, image: team.image, teamId: team.id, height: headerHeight, canManageMembers: canManageMembers)
                ) { }
                    .textCase(nil)
                    .listRowInsets(EdgeInsets())
                    .frame(width: gr.size.width)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .listSectionSpacing(75)
                membersList
            }
            .ignoresSafeArea(edges: .top)
            .listStyle(.plain)
        }
    }
    
    private var membersList: some View {
        ForEach(sortedMembers, id: \.uid) { member in
            row(for: member)
                .actionSheet(isPresented: $showRoleActionSheet) {
                    ActionSheet(
                        title: Text("Couldn’t change role"),
                        message: Text(roleErrorMessage),
                        buttons: [.cancel(Text("OK"))]
                    )
                }
                .swipeActions {
                    if canManageMembers {
                        Button(role: .destructive) {
                            teamsVM.removeMember(teamId: team.id, memberUid: member.uid)
                        } label: {
                            Label("Remove", systemImage: "minus.circle")
                        }
                    }
                }
        }
    }
    
    private func row(for member: TeamMemberEntry) -> some View {
        HStack {
            UserRowView(uid: member.uid)
            Spacer()
            menu(member)
        }
    }
    
    private func menu(_ member: TeamMemberEntry) -> some View {
        Group {
            if canManageMembers {
                Menu {
                    ForEach(TeamRole.allCases, id: \.self) { role in
                        Button {
                            changeRoleTapped(teamId: team.id, member: member, newRole: role)
                        } label: {
                            HStack {
                                Text(role.displayName)
                                if role == member.role { Image(systemName: "checkmark") }
                            }
                        }
                    }
                } label: {
                    HStack {
                        Text(member.role.displayName)
                        Image(systemName: "chevron.up.chevron.down")
                    }
                    .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            } else {
                Text(member.role.displayName)
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    func changeRoleTapped(teamId: String, member: TeamMemberEntry, newRole: TeamRole) {
        teamsVM.changeRoleWithOwnerGuard(teamId: teamId, memberUid: member.uid, newRole: newRole) { err in
            if let err {
                roleErrorMessage = err.localizedDescription
                showRoleActionSheet = true
            }
        }
    }
}

#Preview {
    ManageTeamView(team: .init(
        id: "",
        name: "Team Name",
        ownerUid: "",
        members: [
            TeamMemberEntry(uid: "v51yL1dwlQWFCAGfMWPuvpVUUXl1", role: .owner),
            TeamMemberEntry(uid: "8wsO3dRoOaddUm6fJbRVS9JhWQv2", role: .admin),
            TeamMemberEntry(uid: "zDtFx2cgaUcLf4XWjbVuEf6Y34v1", role: .member),
            TeamMemberEntry(uid: "1hFLgF40QDfjhvcgJ7L06H5t4nS2", role: .member),
            TeamMemberEntry(uid: "s3KpZYX3b8ZuOWmSz1hoTeB2XXC3", role: .member),
        ],
        image: "hammer",
        color: .indigo
    ))
}
