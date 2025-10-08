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
    @State var imageLabel: String = "person.3"
    @State var name: String = ""
    @State var colorLabel: Color = K.Colors.accent
    
    var body: some View {
        list
            .navigationBarTitle("Create Team")
            .navigationDestination(item: $navTarget) { target in
                AddMembersView(teamId: target.id, initialMembers: [], existingMembers: [])
                    .onDisappear {
                        presentationMode.wrappedValue.dismiss()
                    }
            }
    }
    
    private var list: some View {
        GlassList {
            nameSection
            imageSection
            colorSection
            if !isNameFocused {
                buttonSection
            }
        }
    }
    
    private var nameSection: some View {
        Section {
            nameTextField
        } header: {
            Text("Name Your Team")
        }
    }
    
    private var nameTextField: some View {
        TextField("Team Name", text: $name)
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
    
    private var imageSection: some View {
        Section {
            VStack(alignment: .leading) {
                Text("Pick an Icon")
                imageScroll
            }
        }
    }
    
    private var imageScroll: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(K.SFSymbols.teamArray, id: \.self) { symbol in
                        imageIcon(symbol)
                            .onTapGesture {
                                imageLabel = symbol
                                withAnimation {
                                    proxy.scrollTo(symbol, anchor: .center)
                                }
                            }
                            .id(symbol)
                    }
                }
                .padding(.vertical, 4)
            }
            .onAppear {
                DispatchQueue.main.async {
                    withAnimation {
                        proxy.scrollTo(imageLabel, anchor: .center)
                    }
                }
            }
        }
    }
    
    private var iamgeLabel: some View {
        HStack {
            Image(systemName: imageLabel)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: 25)
            Image(systemName: "chevron.up.chevron.down")
        }
    }
    
    private var colorSection: some View {
        Section {
            HStack {
                Text("Selec a color: ")
                Spacer()
                Menu {
                    ForEach(K.Colors.teamColors, id:\.self) { color in
                        Button {
                            colorLabel = color
                        }label: {
                            HStack {
                                Circle()
                                    .fill(color)
                                Text(K.Colors.colorName(color))
                            }
                        }
                    }
                }label: {
                    HStack {
                        Circle()
                            .fill(colorLabel)
                            .frame(width: 15, height: 15)
                        Text(K.Colors.colorName(colorLabel))
                    }
                }
            }
        }
    }

    private var buttonSection: some View {
        Section {
            button
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
        }
        .listSectionSpacing(15)
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
    
    @ViewBuilder
    private func imageIcon(_ symbol: String) -> some View {
        Image(systemName: symbol)
            .resizable()
            .scaledToFit()
            .frame(width: 30, height: 30)
            .padding(8)
            .background(symbol == imageLabel ? K.Colors.accent.opacity(0.2) : Color.clear)
            .cornerRadius(8)
    }
    
    private func create() {
        Task {
            if let teamId = await vm.createTeam(name: name, image: imageLabel, color: colorLabel) {
                isNameFocused = false
                navTarget = NavTeam(id: teamId)
            }
        }
    }
}

#Preview {
    CreateTeamView()
        .environmentObject(CreateTeamViewModel())
}
