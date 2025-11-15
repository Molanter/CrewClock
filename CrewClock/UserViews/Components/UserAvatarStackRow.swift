//
//  UserAvatarStackRow.swift
//  CrewClock
//
//  Created by Edgars Yarmolatiy on 11/15/25.
//

import SwiftUI

struct UserAvatarStackRow: View {
    let uids: [String]
    var size: CGFloat = 40
    var overlap: CGFloat = 12   // how much they overlap

    var body: some View {
        HStack(spacing: -overlap) {
            ForEach(Array(uids.enumerated()), id: \.offset) { index, uid in
                UserAvatarFromUID(uid: uid)
                    .frame(width: size, height: size)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(Color.gray, lineWidth: 1)
                    )
                    .zIndex(Double(index)) // first image under, last image on top
            }
        }
    }
}
