//
//  ProfileView.swift
//  CrewClock
//
//  Created by Edgars Yarmolatiy on 11/1/25.
//

import SwiftUI
import FirebaseAuth

struct ProfileView: View {
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject private var connectionsVM: ConnectionsViewModel

    /// If nil → load current user’s profile
    let uid: String?

    @StateObject private var vm = ProfileViewModel()
    @State private var showReport = false
    @State private var showDisconnectAlert = false
    
    private var sheetStrokeColor: Color {
        colorScheme == .dark ? .white.opacity(0.3) : .black.opacity(0.3)
    }

    var body: some View {
        NavigationStack {
            list
                .sheet(isPresented: $showReport) { ReportView() }
                .onAppear {
                    vm.loadUser(uid: uid)
                    // Ensure we have the signed-in user's connection list to evaluate status.
                    connectionsVM.fetchAllConnections()
                }
        }
    }

    private var list: some View {
        ScrollView {
            profileHeader
                .padding(.horizontal, K.UI.padding)

            statsScrollBar
                .padding(.horizontal, K.UI.padding)
                .padding(.vertical, K.UI.padding/2)
            
            mainButtonsRow
                .padding(.horizontal, K.UI.padding)
        }
//        .scrollContentBackground(.hidden)
//        .background { ListBackground() }
    }

    private var profileHeader: some View {
        VStack(alignment: .leading) {
            HStack {
                profilePicturePart
                Spacer()
            }
            nameRow
            profileHeaderDivider
            descriptionRow
            if let tags = vm.viewedUser?.tags, !tags.isEmpty {
                tagsRow
            }
        }
        .padding(K.UI.padding)
        .frame(maxWidth: .infinity)
        .background {
            GlassBlur(removeAllFilters: true, blur: 5)
                .cornerRadius(K.UI.cornerRadius)
                .overlay(
                    RoundedRectangle(cornerRadius: K.UI.cornerRadius)
                        .stroke(sheetStrokeColor, lineWidth: 1.5)
                )
        }
    }

    private var profilePicturePart: some View {
        ZStack(alignment: .bottomTrailing) {
            ZStack {
                if let imageString = vm.viewedUser?.profileImage {
                    UserProfileImageCircle(imageString)
                }else {
                    Image(systemName: "person.crop.circle")
                        .resizable()
                }
            }
                .frame(width: 75, height: 75)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(Color.gray, lineWidth: 1)
                )
                .shadow(color: shadowColor(), radius: 10)
                .padding(5)
            
            connectionOverlay()
        }
    }

    @ViewBuilder
    private func connectionOverlay() -> some View {
        // Only for other users. Hide for self.
        if !isViewingSelf() {
            let status = connectionStatusForViewed()
            switch status {
            case .some(.accepted):
                EmptyView() // hide when connected
            case .some(.pending):
                // show a pending indicator
                Image(systemName: "hourglass")
                    .padding(5)
                    .background {
                        TransparentBlurView(removeAllFilters: false)
                            .blur(radius: 5, opaque: true)
                            .background(colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.1))
                    }
                    .clipShape(Circle())
                    .foregroundStyle(.secondary)
            default:
                // no relation / blocked / rejected → show plus to suggest connect
                Image(systemName: "plus")
                    .padding(5)
                    .background {
                        TransparentBlurView(removeAllFilters: false)
                            .blur(radius: 5, opaque: true)
                            .background(colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.1))
                    }
                    .clipShape(Circle())
            }
        }
    }

    private var profileHeaderDivider: some View {
        RoundedRectangle(cornerRadius: 1)
            .frame(height: 1)
            .foregroundStyle(.secondary)
            .padding(5)
    }

    private var nameRow: some View {
        HStack {
            Text(vm.viewedUser?.name.isEmpty == false ? vm.viewedUser!.name : "User")
                .font(.title2.bold())
                .redacted(reason: vm.isLoading ? .placeholder : [])
            Spacer()
            if let city = vm.viewedUser?.city, let country = vm.viewedUser?.country {
                Group {
                    if !city.isEmpty, !country.isEmpty {
                        Text("\(city), \(country)")
                    }else if !city.isEmpty, country.isEmpty {
                        Text("\(city)")
                    }else if city.isEmpty, !country.isEmpty {
                        Text("\(country)")
                    }
                }
                .foregroundStyle(.secondary)
                .font(.body)
            }
        }
    }

    private var descriptionRow: some View {
        Text(vm.viewedUser?.description ?? "No bio yet.")
            .font(.body)
            .redacted(reason: vm.isLoading ? .placeholder : [])
    }
    
    private var tagsRow: some View {
        Group {
            if let tags = vm.viewedUser?.tags, !tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(tags, id: \.self) { tag in
                            Text("#\(tag)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(
                                    Capsule()
                                        .fill(Color.secondary.opacity(0.1))
                                )
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }


    private var statsScrollBar: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 10) {
                NavigationLink {
                    if let vuid = vm.viewedUser?.uid {
                        UserConnectionsView(viewingUid: vuid)
                            .environmentObject(connectionsVM)
                    } else {
                        Text("Connections")
                    }
                } label: {
                    ProfileStatsView(number: 100, text: "Connections")
                }
                ProfileStatsView(number: 35, text: "Projects")
                ProfileStatsView(number: 30, text: "Clients")
            }
            .buttonStyle(.plain)
            .tint(.primary)
        }
        .scrollIndicators(.hidden)
        .cornerRadius(K.UI.cornerRadius)
    }

    private var mainButtonsRow: some View {
        HStack(spacing: 10) {
            mainButton

            Menu {
                Button {
                    showReport.toggle()
                } label: {
                    Label("Report", systemImage: "exclamationmark.triangle")
                        .tint(.red)
                }
            } label: {
                Image(systemName: "ellipsis")
                    .frame(width: 30, height: 30)
            }
            .frame(width: 45, height: 45)
            .background {
                TransparentBlurView(removeAllFilters: false)
                    .blur(radius: 5, opaque: true)
                    .background(colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.1))
            }
            .clipShape(Circle())
        }
        .buttonStyle(.plain)
    }
    
    private var mainButton: some View {
        Group {
            if isViewingSelf() {
                NavigationLink {
                    ProfileEditView()
                } label: {
                    Label("Edit Profile", systemImage: "pencil")
                        .padding(K.UI.padding)
                        .frame(maxWidth: .infinity)
                        .frame(height: 45)
                        .background(K.Colors.accent)
                        .clipShape(Capsule())
                }
            } else {
                Button {
                    let status = connectionStatusForViewed()
                    if status == .accepted {
                        showDisconnectAlert = true            // tap "Connected" → ask to disconnect
                    } else {
                        connectIfNeeded()                     // send or re-open invite
                    }
                } label: {
                    Label(connectButtonTitle(), systemImage: "link")
                        .padding(K.UI.padding)
                        .frame(maxWidth: .infinity)
                        .frame(height: 45)
                        .foregroundStyle(connectButtonForeground())
                        .background(connectButtonBackground())
                        .overlay(
                            Capsule()
                                .stroke(Color.gray.opacity(connectButtonBackground() == .clear ? 0.4 : 0.0), lineWidth: 1)
                        )
                        .clipShape(Capsule())
                }
                .disabled(connectButtonDisabled())
                .alert("Disconnect?", isPresented: $showDisconnectAlert) {
                    Button("Cancel", role: .cancel) {}
                    Button("Disconnect", role: .destructive) { disconnectIfConfirmed() }
                } message: {
                    Text("This will remove the connection. You can reconnect later.")
                }
            }
        }
    }

    // Helper for self-profile detection
    private func isViewingSelf() -> Bool {
        vm.isSelf(viewedUid: vm.viewedUser?.uid)
    }

    // MARK: - Connect logic

    /// Single public action: connect if not connected. No-op when already connected or self.
    private func connectIfNeeded() {
        guard let other = vm.viewedUser?.uid else { return }
        if vm.isSelf(viewedUid: other) { return }

        let status = vm.connectionStatus(with: other, connections: connectionsVM.connections)
        switch status {
        case nil:
            // No relationship yet → send invite
            connectionsVM.connectWithPerson(other)
        case .some(.blocked), .some(.rejected):
            // Re-open as pending
            connectionsVM.connectWithPerson(other)
        default:
            // pending/accepted/blocked → do nothing here
            break
        }
        // Refresh local list so UI status capsule updates
        connectionsVM.fetchAllConnections()
    }

    private func connectButtonTitle() -> String {
        guard let other = vm.viewedUser?.uid else { return "Connect" }
        let status = vm.connectionStatus(with: other, connections: connectionsVM.connections)
        switch status {
        case nil: return "Connect"
        case .some(.pending): return "Pending"
        case .some(.accepted): return "Connected"
        case .some(.blocked), .some(.rejected): return "Reconnect"
        }
    }
    
    private func connectionStatusForViewed() -> ConnectionStatus? {
        guard let other = vm.viewedUser?.uid else { return nil }
        return vm.connectionStatus(with: other, connections: connectionsVM.connections)
    }

    private func connectButtonForeground() -> Color {
        switch connectionStatusForViewed() {
        case nil:                return .white          // no relation yet
        case .some(.pending):    return .white
        case .some(.blocked),
             .some(.rejected):   return .white
        case .some(.accepted):   return .green         // text green when connected
        }
    }

    private func connectButtonBackground() -> Color {
        switch connectionStatusForViewed() {
        case nil:                return .green          // invite → green
        case .some(.pending):    return .gray.opacity(0.6)
        case .some(.blocked),
             .some(.rejected):   return .gray.opacity(0.6)
        case .some(.accepted):   return .clear         // connected → clear bg
        }
    }

    private func connectButtonDisabled() -> Bool {
        guard let other = vm.viewedUser?.uid, !vm.isSelf(viewedUid: other) else { return true }
        let status = vm.connectionStatus(with: other, connections: connectionsVM.connections)
        return status == .pending
    }
    
    private func disconnectIfConfirmed() {
        guard let other = vm.viewedUser?.uid else { return }
        connectionsVM.removeConnection(other)
        connectionsVM.fetchAllConnections()
    }
    // MARK: - Utils

    private func shadowColor() -> Color {
        colorScheme == .dark ? Color.black.opacity(0.2) : Color.white.opacity(0.2)
    }
}

// MARK: - Preview
#Preview("Light") {
    ProfileView(uid: nil)
        .preferredColorScheme(.light)
        .environmentObject(ConnectionsViewModel())
}

#Preview("Dark") {
    ProfileView(uid: nil)
        .preferredColorScheme(.dark)
        .environmentObject(ConnectionsViewModel())
}
