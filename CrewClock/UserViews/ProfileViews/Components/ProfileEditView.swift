//
//  ProfileEditView.swift
//  CrewClock
//
//  Created by Edgars Yarmolatiy on 11/3/25.
//

import SwiftUI
import PhotosUI

struct ProfileEditView: View {
    @EnvironmentObject var userVM: UserViewModel
    @StateObject private var vm = ProfileEditViewModel()

    @State private var newTag: String = ""
    @State private var newLanguage: String = ""

    var body: some View {
        Form {
            Section("Photo") {
                HStack(spacing: 16) {
                    ZStack {
                        if let img = vm.avatarPreview {
                            img.resizable().scaledToFill()
                        } else if let url = URL(string: userVM.user?.profileImage ?? ""), !url.absoluteString.isEmpty {
                            AsyncImage(url: url) { phase in
                                switch phase {
                                case .success(let image): image.resizable().scaledToFill()
                                default: Image(systemName: "person.crop.circle").resizable().scaledToFit()
                                }
                            }
                        } else {
                            Image(systemName: "person.crop.circle").resizable().scaledToFit()
                        }
                    }
                    .frame(width: 72, height: 72)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(.quaternary, lineWidth: 1))

                    PhotosPicker("Change photo", selection: $vm.pickerItem, matching: .images)
                        .onChange(of: vm.pickerItem) { _ in
                            Task { await vm.handlePickedPhoto() }
                        }
                }
            }

            Section("Basic info") {
                TextField("Name", text: $vm.name)
                    .textInputAutocapitalization(.words)
                TextField("Description", text: $vm.descriptionText, axis: .vertical)
                    .lineLimit(3...6)
            }

            Section("Location") {
                TextField("City", text: $vm.city)
                TextField("Country", text: $vm.country)
            }

            Section {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        TextField("Add tag", text: $newTag)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                        Button("Add") {
                            let t = newTag.trimmingCharacters(in: .whitespacesAndNewlines)
                            if !t.isEmpty && !vm.tags.contains(where: { $0.caseInsensitiveCompare(t) == .orderedSame }) {
                                vm.tags.append(t)
                            }
                            newTag = ""
                        }
                    }

                    WrapChips(items: vm.tags) { tag in
                        HStack(spacing: 6) {
                            Text(tag)
                            Button {
                                vm.tags.removeAll { $0 == tag }
                            } label: { Image(systemName: "xmark.circle.fill") }
                            .buttonStyle(.borderless)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(Color(.systemGray5)))
                    }
                }
            } header: { Text("Tags") }

            Section {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        TextField("Add language", text: $newLanguage)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                        Button("Add") {
                            let l = newLanguage.trimmingCharacters(in: .whitespacesAndNewlines)
                            if !l.isEmpty && !vm.languages.contains(where: { $0.caseInsensitiveCompare(l) == .orderedSame }) {
                                vm.languages.append(l)
                            }
                            newLanguage = ""
                        }
                    }

                    WrapChips(items: vm.languages) { lang in
                        HStack(spacing: 6) {
                            Text(lang)
                            Button {
                                vm.languages.removeAll { $0 == lang }
                            } label: { Image(systemName: "xmark.circle.fill") }
                            .buttonStyle(.borderless)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(Color(.systemGray5)))
                    }
                }
            } header: { Text("Languages") }

            Section {
                Button {
                    Task { await vm.save(userVM: userVM) }
                } label: {
                    if vm.isSaving { ProgressView() } else { Text("Save changes") }
                }
                .disabled(vm.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .navigationTitle("Edit Profile")
        .onAppear {
            vm.prefill(from: userVM.user)
            if userVM.user == nil {
                userVM.fetchUser()
            }
        }
        .alert("Saved", isPresented: $vm.saveDone) {
            Button("OK", role: .cancel) { vm.saveDone = false }
        }
        .alert("Error", isPresented: .constant(vm.error != nil), actions: {
            Button("OK", role: .cancel) { vm.error = nil }
        }, message: { Text(vm.error ?? "") })
    }
}

// Simple chip layout
struct WrapChips<Content: View>: View {
    let items: [String]
    let chip: (String) -> Content

    init(items: [String], @ViewBuilder chip: @escaping (String) -> Content) {
        self.items = items
        self.chip = chip
    }

    var body: some View {
        var width: CGFloat = 0
        var height: CGFloat = 0

        return GeometryReader { geo in
            ZStack(alignment: .topLeading) {
                ForEach(items, id: \.self) { item in
                    chip(item)
                        .padding(4)
                        .alignmentGuide(.leading) { d in
                            if abs(width - d.width) > geo.size.width {
                                width = 0
                                height -= d.height
                            }
                            let result = width
                            if item == items.last { width = 0 }
                            width += d.width
                            return result
                        }
                        .alignmentGuide(.top) { _ in
                            let result = height
                            if item == items.last { height = 0 }
                            return result
                        }
                }
            }
        }.frame(minHeight: 44)
    }
}
