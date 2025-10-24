//
//  SupportView.swift
//  CrewClock
//
//  Created by Edgars Yarmolatiy on 10/23/25.
//


import SwiftUI

struct SupportView: View {
    @StateObject private var vm = SupportViewModel()
    @Environment(\.openURL) private var openURL

    var body: some View {
        NavigationStack {
            GlassList {
                Section("Category") {
                    Picker("Type", selection: $vm.category) {
                        ForEach(SupportViewModel.Category.allCases) { c in
                            Text(c.rawValue).tag(c)
                        }
                    }
                    .pickerStyle(.menu)
                }

                Section("Details") {
                    TextField("Subject", text: $vm.subject)
                        .textInputAutocapitalization(.sentences)
                    TextEditor(text: $vm.message)
                        .frame(minHeight: 140)
                        .overlay(alignment: .topLeading) {
                            if vm.message.isEmpty {
                                Text("Describe the issue or question…")
                                    .foregroundStyle(.secondary)
                                    .padding(.top, 8)
                                    .padding(.leading, 5)
                            }
                        }
                }

                Section {
                    Toggle("Include diagnostics (recommended)", isOn: $vm.includeDiagnostics)
                } footer: {
                    Text("Diagnostics include app version, iOS version, device model, and your account ID if signed in.")
                }

                Section {
                    Button {
                        Task { await vm.submit() }
                    } label: {
                        if vm.isSending {
                            ProgressView().frame(maxWidth: .infinity)
                        } else {
                            Text("Submit Ticket").frame(maxWidth: .infinity)
                        }
                    }
                    .disabled(!vm.valid || vm.isSending)
                }

                Section("Quick help") {
                    NavigationLink{
                        FAQListView()
                    }label: {
                        Label("Browse FAQs", systemImage: "questionmark.circle")
                            .hideTabBarWhileActive("FAQs")
                    }
                    Button {
                        openURL(URL(string: "mailto:molanter0109@gmail.com")!)
                    } label: {
                        Label("Email Support", systemImage: "envelope")
                    }
                    .buttonStyle(.plain)
                }

                if let err = vm.errorMessage {
                    Section {
                        Text(err).foregroundStyle(.red)
                    }
                }
                if vm.sendSuccess {
                    Section {
                        Label("Thanks! Your message was sent.", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    }
                }
            }
            .navigationTitle("Support")
        }
    }
}
