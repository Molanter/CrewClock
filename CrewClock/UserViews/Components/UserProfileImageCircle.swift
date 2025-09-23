//
//  UserProfileImage.swift
//  CrewClock
//
//  Created by Edgars Yarmolatiy on 7/26/25.
//

import SwiftUI

struct UserProfileImageCircle: View {
    let imageString: String
    
    init(_ imageString: String) {
        self.imageString = imageString
    }
    
    var body: some View {
        AsyncImage(url: URL(string: imageString)) { phase in
                switch phase {
                case .empty:
                    ProgressView() // While loading
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFit()
                case .failure:
                    Image(systemName: "person.crop.circle.dashed")
                @unknown default:
                    EmptyView()
                }
            }
            .aspectRatio(contentMode: .fill)
            .cornerRadius(.infinity)
    }
}

#Preview {
    UserProfileImageCircle("none")
}
