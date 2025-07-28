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
    
    var body: some View {
        Group {
            if let user = userViewModel.getUser(uid) {
                HStack {
                    profileImage(for: user)
                    VStack(alignment: .leading) {
                        Text(user.name)
                            .font(.headline)
                        Text(user.email)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                }
            } else {
                ProgressView("Loading...")
            }
        }
        .onAppear {
            userViewModel.fetchUser(by: uid)
        }
    }
    
    @ViewBuilder
    private func profileImage(for user: UserFB) -> some View {
         let urlString = user.profileImage
           if let url = URL(string: urlString) {
               UserProfileImage(url.absoluteString)
            .frame(width: 40, height: 40)
            .clipShape(Circle())
        } else {
            initialsCircle(user)
        }
    }
    
    private func initialsCircle(_ user: UserFB) -> some View {
        let initials: String = {
            let components = (user.name).components(separatedBy: " ")
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
