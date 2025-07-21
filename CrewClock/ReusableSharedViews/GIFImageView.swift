//
//  GIFImageView.swift
//  CrewClock
//
//  Created by Edgars Yarmolatiy on 7/20/25.
//

import SwiftUI
import SDWebImageSwiftUI

struct GIFImageView: View {
    let url: URL

    var body: some View {
        AnimatedImage(url: url)
            .indicator(.activity)
//            .loopCount(0) // Infinite loop BEFORE resizable
            .resizable()
            .scaledToFit()
//            .frame(width: 100, height: 100)
    }
}

#Preview {
    GIFImageView(url: URL(string: "https://firebasestorage.googleapis.com/v0/b/crewclock-9a62b.firebasestorage.app/o/emoji%2FAnimatedEmojies-512px-327.gif?alt=media&token=aeb8e45e-c33e-4839-85dd-fd501318d6e6")!)
}
