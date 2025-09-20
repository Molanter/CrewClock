//
//  MyTeamsView.swift
//  CrewClock
//
//  Created by Edgars Yarmolatiy on 9/18/25.
//


import SwiftUI

struct MyTeamsView: View {
    @StateObject private var vm = MyTeamsViewModel()

    @State private var showOwned = true
    @State private var showMember = true

    var body: some View {
        GlassList {
            if vm.isLoading {
                Section { ProgressView().frame(maxWidth: .infinity) }
            }
            if !vm.errorMessage.isEmpty {
                Section {
                    Text(vm.errorMessage).foregroundStyle(.red)
                }
            }

            Section {
                DisclosureGroup(isExpanded: $showOwned) {
                    if vm.owned.isEmpty {
                        Text("No teams yet.").foregroundStyle(.secondary)
                    } else {
                        ForEach(vm.owned) { team in
                            row(team)
                        }
                    }
                } label: {
                    HStack {
                        Text("Owned by me")
                        Spacer()
                        Text("\(vm.owned.count)")
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Section {
                DisclosureGroup(isExpanded: $showMember) {
                    if vm.memberOf.isEmpty {
                        Text("No teams joined yet.").foregroundStyle(.secondary)
                    } else {
                        ForEach(vm.memberOf) { team in
                            row(team)
                        }
                    }
                } label: {
                    HStack {
                        Text("I’m a member")
                        Spacer()
                        Text("\(vm.memberOf.count)")
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .navigationTitle("My Teams")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    vm.start()
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
            }
        }
        .onAppear { vm.start() }
    }

    private func row(_ team: TeamFB) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(team.name).font(.body)
                Text("\(team.memberCount) member\(team.memberCount == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundStyle(.tertiary)
        }
        .contentShape(Rectangle())
        // Hook up navigation to your Team detail if you have one:
        // .onTapGesture { /* navigate to TeamDetail(teamId: team.id) */ }
    }
}
