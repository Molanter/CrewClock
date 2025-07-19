//
//  UserRowView.swift
//  CrewClock
//
//  Created by Edgars Yarmolatiy on 6/12/25.
//

import SwiftUI

import FirebaseFirestore

struct UserRowView: View {
    @EnvironmentObject private var userViewModel: UserViewModel
    
    var uid: String
    
    var user: UserFB? {
        return userViewModel.getUser(uid)
    }

    var body: some View {
        HStack {
            profileImage
            VStack(alignment: .leading) {
                Text(user?.name ?? "Loading...")
                    .font(.headline)
                Text(user?.email ?? "")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
        }
        .onAppear {
            userViewModel.fetchUser(by: uid)
        }
    }
    
    @ViewBuilder
    private var profileImage: some View {
        if let urlString = user?.profileImage,
           let url = URL(string: urlString) {
            AsyncImage(url: url) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                ProgressView()
            }
            .frame(width: 40, height: 40)
            .clipShape(Circle())
        } else {
            initialsCircle
        }
    }
    
    private var initialsCircle: some View {
        let initials: String = {
            let components = (user?.name ?? "").components(separatedBy: " ")
            let firstTwo = components.prefix(2)
            return firstTwo.compactMap { $0.first }.map { String($0).uppercased() }.joined()
        }()

        return ZStack {
            Circle()
                .fill(Color.blue)
                .frame(width: 40, height: 40)
            Text(initials)
                .foregroundColor(.white)
                .font(.headline)
        }
    }
}

#Preview {
    UserRowView(uid: "v51yL1dwlQWFCAGfMWPuvpVUUXl1")
        .environmentObject(UserViewModel())
}
