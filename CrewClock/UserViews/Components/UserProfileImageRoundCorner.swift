//
//  UserProfileImageRoundCorner.swift
//  CrewClock
//
//  Created by Edgars Yarmolatiy on 7/26/25.
//

import SwiftUI

struct UserProfileImageRoundCorner: View {
    let imageString: String
    
    init(_ imageString: String) {
        self.imageString = imageString
    }
    
    var body: some View {
        GeometryReader { proxy in
            let side = min(proxy.size.width, proxy.size.height)
            let shape = RoundedRectangle(cornerRadius: K.UI.cornerRadius / 1.3)

            AsyncImage(url: URL(string: imageString)) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                        .frame(width: side, height: side)
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(width: side, height: side)
                case .failure:
                    Image(systemName: "person.crop.square.fill")
                        .resizable()
                        .scaledToFill()
                        .frame(width: side, height: side)
                @unknown default:
                    EmptyView()
                        .frame(width: side, height: side)
                }
            }
            .clipShape(shape)
            .frame(width: proxy.size.width, height: proxy.size.height, alignment: .center)
        }
    }
}

#Preview {
    UserProfileImageRoundCorner("https://media.newyorker.com/photos/665f65409ad64d9e7a494208/4:3/w_1003,h_752,c_limit/Chayka-screenshot-06-05-24.jpg")
        .frame(width: 100, height: 100)
}
