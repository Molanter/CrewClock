//
//  ProfileEditView.swift
//  CrewClock
//
//  Created by Edgars Yarmolatiy on 11/3/25.
//

import SwiftUI
import PhotosUI

struct ProfileEditView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var userVM: UserViewModel
    @StateObject private var vm = ProfileEditViewModel()

    @State private var newTag: String = ""
    @State private var newLanguage: String = ""
    @State private var showLegacyPicker = false
    @State private var showCountryPicker = false
    @State private var countryQuery = ""
    private let allCountries: [String] = {
        Locale.isoRegionCodes
            .compactMap { Locale.current.localizedString(forRegionCode: $0) }
            .sorted()
    }()

    var isFinishingProfile: Bool = false

    var body: some View {
        GlassList {
            // Profile photo picker and preview
            photoSection
            
            // Required basic fields
            basicInfoSection
            
            // Location (at least Country required)
            locationSection
            locationHelperSection
            
            // Tags (at least one required)
            tagsSection
            tagChipsSection
            
            // Languages (at least one required)
            languagesSection
            languageChipsSection
            
            // Save CTA
            saveSection
        }
        .navigationTitle(isFinishingProfile ? "Finish Your Profile" : "Edit Profile")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Save") {
                    saveFunc()
                }
                .disabled(vm.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .onAppear {
            // Pre-fill from the current user object and lazy-load if missing
            vm.prefill(from: userVM.user)
            if userVM.user == nil {
                userVM.fetchUser()
            }
        }
        .alert("Error", isPresented: .constant(vm.error != nil), actions: {
            Button("OK", role: .cancel) { vm.error = nil }
        }, message: { Text(vm.error ?? "") })
        .hideTabBarWhileActive("edit")
    }

    // MARK: - Sections (private computed views)
    
    /// Photo picker section
    private var photoSection: some View {
        Section("Photo") {
            HStack(spacing: 16) {
                avatarPreview
                changePhotoButton
            }
        }
    }

    /// Circular avatar preview (current or picked)
    private var avatarPreview: some View {
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
    }

    /// System crop flow using UIImagePickerController (allowsEditing)
    private var changePhotoButton: some View {
        Button("Change photo") { showLegacyPicker = true }
            .sheet(isPresented: $showLegacyPicker) {
                LegacyImagePicker(allowsEditing: true) { img in
                    vm.setAvatarImage(img)
                    showLegacyPicker = false
                } onCancel: {
                    showLegacyPicker = false
                }
            }
    }
    
    /// Basic user information (required: name, description)
    private var basicInfoSection: some View {
        Section("Basic info") {
            TextField("Name *", text: $vm.name)
                .textInputAutocapitalization(.words)
            TextField("Description *", text: $vm.descriptionText, axis: .vertical)
                .lineLimit(3...6)
        }
    }
    
    /// Location section (at least Country required)
    private var locationSection: some View {
        Section {
            TextField("City", text: $vm.city)
                .textContentType(.addressCity)
            TextField("Country *", text: $vm.country)
                .textContentType(.countryName)
        }
    }
    
    private var locationHelperSection: some View {
        Section {
            countryHelperRow
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
        }footer: {
            Text("At least country is required")
                .font(.footnote)
                .foregroundStyle(vm.country.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .red : .secondary)
        }
        .listSectionSpacing(5)
    }

    /// Quick helpers to fill the Country field
    private var countryHelperRow: some View {
        HStack(spacing: 10) {
            Button {
                showCountryPicker = true
            } label: {
                Label("Pick from list", systemImage: "list.bullet")
                    .font(.caption)
            }
            .buttonStyle(.bordered)

            Button {
                if let code = Locale.current.region?.identifier,
                   let name = Locale.current.localizedString(forRegionCode: code) {
                    vm.country = name
                }
            } label: {
                Label("Use current", systemImage: "location")
                    .font(.caption)
            }
            .buttonStyle(.bordered)
        }
        .tint(.secondary)
        .sheet(isPresented: $showCountryPicker) {
            NavigationStack {
                List(filteredCountries, id: \.self) { country in
                    Button(country) {
                        vm.country = country
                        showCountryPicker = false
                    }
                }
                .navigationTitle("Select Country")
                .searchable(text: $countryQuery, placement: .navigationBarDrawer(displayMode: .always))
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Done") { showCountryPicker = false }
                    }
                }
                .tint(.primary)
            }
        }
    }

    private var filteredCountries: [String] {
        let q = countryQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        if q.isEmpty { return allCountries }
        return allCountries.filter { $0.localizedCaseInsensitiveContains(q) }
    }
    
    /// Tags input with chips (at least one required)
    private var tagsSection: some View {
        Section {
            tagInputRow
        } header: { Text("Tags *") }
    }
    
    private var tagChipsSection: some View {
        Section {
            tagChips
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
        }footer: {
            Text("At least one required")
                .font(.footnote)
                .foregroundStyle(vm.tags.count < 1 ? Color.red : Color.secondary)
        }
        .listSectionSpacing(5)
    }

    /// Inline row to add a single tag
    private var tagInputRow: some View {
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
    }

    /// Chips list of added tags with remove action
    private var tagChips: some View {
        WrapChips(items: vm.tags) { tag in
            HStack(spacing: 5) {
                Text(tag)
                Button {
                    vm.tags.removeAll { $0 == tag }
                } label: { Image(systemName: "xmark.circle.fill") }
                .buttonStyle(.borderless)
                .tint(.red)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Capsule().fill(Color(.systemGray5)))
        }
    }
    
    /// Languages input with chips (at least one required)
    private var languagesSection: some View {
        Section {
                languageInputRow
        } header: { Text("Languages *") }
    }
    
    private var languageChipsSection: some View {
        Section {
            languageChips
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
        }footer: {
            Text(vm.languages.isEmpty ? "At least one language required" : "At least one required")
                .font(.footnote)
                .foregroundStyle(vm.languages.isEmpty ? .red : .secondary)
        }
        .listSectionSpacing(5)
    }

    /// Inline row to add a single language
    private var languageInputRow: some View {
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
    }

    /// Chips list of added languages with remove action
    private var languageChips: some View {
        WrapChips(items: vm.languages) { lang in
            HStack(spacing: 5) {
                Text(lang)
                Button {
                    vm.languages.removeAll { $0 == lang }
                } label: { Image(systemName: "xmark.circle.fill") }
                .buttonStyle(.borderless)
                .tint(.red)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Capsule().fill(Color(.systemGray5)))
        }
    }
    
    /// Primary save action section
    private var saveSection: some View {
        Section { saveButton }
    }

    /// Save button reused by toolbar and section
    private var saveButton: some View {
        Button {
            saveFunc()
        } label: {
            if vm.isSaving {
                ProgressView()
            } else {
                Text("Save changes")
                    .frame(maxWidth: .infinity)
            }
        }
        .disabled(vm.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
    }
    
    //MARK: - Functions
    
    private func saveFunc() {
        Task { await vm.save(userVM: userVM) }
        Toast.shared.present(
            title: "Profile updated",
            symbol: "checkmark",
            isUserInteractionEnabled: true,
            timing: .medium
        )
        dismiss()
    }
}

#Preview {
    ProfileEditView(isFinishingProfile: false)
        .environmentObject(UserViewModel())
}
    
