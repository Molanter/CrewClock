//
//  DeleteAccountView.swift
//  CrewClock
//
//  Created by Edgars Yarmolatiy on 8/14/25.
//


//
//  DeleteAccountView.swift
//  CrewClock
//
//  Created by You on 8/14/25.
//

import SwiftUI
import FirebaseAuth

struct DeleteAccountView: View {
    @StateObject private var vm = AccountDeletionViewModel()

    // If you keep Auth/User VMs in Environment, inject them to refresh UI after deletion
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        GlassList {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Delete Account")
                        .font(.title3.bold())
                    Text("This permanently removes your projects, logs, notifications, profile, and then your sign-in. This **cannot** be undone.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                HStack {
                    Spacer()
                    Button(role: .destructive) {
                        vm.startFirstConfirmation()   // STEP 1 → open confirmationDialog
                    } label: {
                        Label("Delete my account…", systemImage: "trash")
                            .foregroundStyle(.red)
                    }
                    Spacer()
                }
            }
        }
        .navigationTitle("Delete Account")
        .confirmationDialog(
            "Are you absolutely sure?",
            isPresented: Binding(
                get: { vm.phase == .confirming },
                set: { _ in }
            ),
            titleVisibility: .visible
        ) {
            Button("Yes, continue", role: .destructive) {
                vm.goToFinalConfirmation()     // STEP 2 → open final sheet
            }
            Button("Cancel", role: .cancel) {
                vm.cancel()
            }
        } message: {
            Text("This will remove your data and sign-in. You can’t undo this.")
        }
        .sheet(isPresented: Binding(
            get: { vm.phase == .finalConfirm || vm.phase == .needsReauth || vm.phase == .running },
            set: { _ in }
        )) {
            // STEP 3 → final gate (type DELETE) and progress/reauth
            FinalConfirmSheet(vm: vm) {
                // onFinish
                if vm.phase == .done {
                    dismiss()
                }
            }
            .presentationDetents([.medium, .large])
        }
        .alert("Error", isPresented: Binding(
            get: {
                if case .error = vm.phase { return true } else { return false }
            },
            set: { _ in vm.cancel() }
        )) {
            Button("OK", role: .cancel) { vm.cancel() }
        } message: {
            if case .error(let msg) = vm.phase { Text(msg) } else { Text("Unknown error") }
        }
    }
}

private struct FinalConfirmSheet: View {
    @StateObject private var authViewModel = AuthViewModel()

    @ObservedObject var vm: AccountDeletionViewModel
    var onFinish: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            if vm.phase == .needsReauth {
                VStack(spacing: 8) {
                    Text("Re-authenticate required")
                        .font(.headline)
                    Text("For security, please re-sign-in and then press Delete again.")
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)

                    Button {
                        // 🔐 Reauth flow:
                        // If you have a dedicated Google reauth screen, present it here.
                        // After success, set vm.phase = .finalConfirm so user can try again.
                        // Example placeholder:
                        Task {
                            try? await Auth.auth().currentUser?.reload()
                            vm.phase = .finalConfirm
                            authViewModel.signOut()
                        }
                    } label: {
                        Label("Re-authenticate", systemImage: "person.badge.key")
                    }

                    Button("Close", role: .cancel) {
                        vm.cancel()
                        authViewModel.signOut()
                    }
                }
            } else if vm.phase == .running {
                ProgressView(vm.progress.isEmpty ? "Deleting…" : vm.progress)
                    .padding(.top)
                Button("Cancel", role: .cancel) { /* intentionally disabled while running */ }
                    .disabled(true)
            } else if vm.phase == .done {
                Image(systemName: "checkmark.circle.fill").font(.system(size: 46))
                    .foregroundStyle(.green)
                Text("Your account has been deleted.")
                Button("Close") { onFinish() }
            } else {
                // final confirm UI
                Text("Final confirmation")
                    .font(.title)
                Text("Type **Delete** to permanently remove your data and account.")
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                HStack {
                    TextField("Type Delete", text: $vm.confirmText)
                        .textInputAutocapitalization(.characters)
                        .disableAutocorrection(true)
                        .padding(K.UI.padding)
                }
                .background {
                    RoundedRectangle(cornerRadius: K.UI.cornerRadius)
                        .fill(Color(.secondarySystemBackground))
                }
                
                Button(role: .destructive) {
                    vm.permanentlyDeleteAccount()
                } label: {
                    Label("Delete", systemImage: "trash.fill")
                }
                .padding(K.UI.padding)
                .buttonStyle(.borderedProminent)
                .disabled(vm.confirmText.uppercased() != "DELETE")
            }
        }
        .padding()
    }
}

