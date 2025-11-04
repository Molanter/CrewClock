//
//  ReportView.swift
//  CrewClock
//
//  Created by Edgars Yarmolatiy on 11/3/25.
//


import SwiftUI

struct ReportView: View {
    @StateObject private var vm = ReportViewModel()
    @FocusState private var focusedField: Field?

    private enum Field { case title, targetRef, description }

    var body: some View {
        NavigationStack {
            form
            .navigationTitle("Report")
            .onSubmit {
                switch focusedField {
                case .title: focusedField = .targetRef
                case .targetRef: focusedField = .description
                default: break
                }
            }
            .alert("Submitted", isPresented: $vm.submitSuccess) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Thanks. We recorded your report.")
            }
            .alert("Submission Failed", isPresented: .constant(vm.submitError != nil), actions: {
                Button("OK", role: .cancel) { vm.submitError = nil }
            }, message: {
                Text(vm.submitError ?? "")
            })
        }
    }
    
    private var form: some View {
        GlassList {
            aboutSection
            
            descriptionSection

            submitButton
        }
    }
    
    private var aboutSection: some View {
        Section("What is this about?") {
            // Pickers
            typePicker
            saverityPicker
            
            // Text Fields
            titlePart
            relateIdPart

            Toggle("Share my contact info", isOn: $vm.shareContact)
        }

    }
    
    private var typePicker: some View {
        Picker("Type", selection: $vm.targetType) {
            ForEach(ReportTarget.allCases) { t in
                Text(t.label).tag(t)
            }
        }
    }
    
    private var saverityPicker: some View {
        Picker("Severity", selection: $vm.severity) {
            ForEach(ReportSeverity.allCases) { s in
                Text(s.label).tag(s)
            }
        }
    }
    
    private var titlePart: some View {
        TextField("Title", text: $vm.title)
            .textInputAutocapitalization(.sentences)
            .submitLabel(.next)
            .focused($focusedField, equals: .title)
    }
    
    private var relateIdPart: some View {
        TextField("Related ID (optional)", text: $vm.targetRefId)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .keyboardType(.asciiCapable)
            .focused($focusedField, equals: .targetRef)
    }
    
    private var descriptionSection: some View {
        Section("Description") {
            descriptionPart
            characterCount
        }
    }
    
    private var descriptionPart: some View {
        ZStack(alignment: .topLeading) {
            TextEditor(text: $vm.descriptionText)
                .frame(minHeight: 140)
                .focused($focusedField, equals: .description)
            if vm.descriptionText.isEmpty {
                Text("Describe the problem or request. Include steps to reproduce if applicable.")
                    .foregroundStyle(.secondary)
                    .padding(.top, 8)
                    .padding(.leading, 5)
                    .allowsHitTesting(false)
            }
        }
    }
    // Show Char count in Description
    private var characterCount:some View {
        HStack {
            Spacer()
            Text("\(vm.descriptionText.count) chars")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
    
    private var submitButton: some View {
        Section {
            Button {
                Task { await vm.submit() }
            } label: {
                if vm.isSubmitting {
                    ProgressView()
                } else {
                    Text("Submit Report")
                }
            }
            .disabled(!vm.isValid || vm.isSubmitting)
        }
    }
}

#Preview {
    ReportView()
}
