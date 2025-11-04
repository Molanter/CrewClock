//
//  ReportBugView.swift
//  CrewClock
//
//  Created by Edgars Yarmolatiy on 10/23/25.
//


import SwiftUI

struct ReportBugView: View {
    @StateObject private var vm = ReportBugViewModel()

    var body: some View {
        NavigationStack {
            GlassList {
                Section("Severity") {
                    Picker("Severity", selection: $vm.severity) {
                        ForEach(ReportBugViewModel.Severity.allCases) { s in
                            Text(s.rawValue).tag(s)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("Summary") {
                    TextField("Subject", text: $vm.subject)
                        .textInputAutocapitalization(.sentences)
                }

                Section("Steps to reproduce") {
                    ZStack(alignment: .topLeading) {
                        TextEditor(text: $vm.stepsToReproduce)
                            .frame(minHeight: 120)
                            .opacity(1.0)
                        if vm.stepsToReproduce.isEmpty {
                            Text("1) …\n2) …\n3) …")
                                .foregroundStyle(.secondary)
                                .padding(.top, 8)
                                .padding(.leading, 5)
                                .allowsHitTesting(false)
                        }
                    }
                }

                Section("Description") {
                    ZStack(alignment: .topLeading) {
                        TextEditor(text: $vm.actualResult)
                            .frame(minHeight: 120)
                            .opacity(1.0)
                        if vm.actualResult.isEmpty {
                            Text("Describe what you expected vs what happened…")
                                .foregroundStyle(.secondary)
                                .padding(.top, 8)
                                .padding(.leading, 5)
                                .allowsHitTesting(false)
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
                            Text("Submit Bug Report").frame(maxWidth: .infinity)
                        }
                    }
                    .tint(K.Colors.accent)
                    .disabled(!vm.isValid || vm.isSending)
                }

                if let err = vm.errorMessage {
                    Section { Text(err).foregroundStyle(.red) }
                }
                if vm.sendSuccess {
                    Section {
                        Label("Thanks! Your report was sent.", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    }
                }
            }
            .navigationTitle("Report a Bug")
        }
    }
}
