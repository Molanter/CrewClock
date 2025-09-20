//
//  ListBackground.swift
//  CrewClock
//
//  Created by Edgars Yarmolatiy on 9/20/25.
//

import SwiftUI

struct ListBackground: View {
    
    var body: some View {
        ZStack(alignment: .center) {
//            LinearGradient(
//                colors: [.blue.opacity(0.5), .green.opacity(0.5), .red.opacity(0.5)],
//                startPoint: .topLeading, endPoint: .bottomTrailing
//            )
            TwoCirclesBackground()
            TransparentBlurView(removeAllFilters: true)
                .blur(radius: 9, opaque: true)
                .background(.white.opacity(0.05))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
