//
//  TwoCirclesBackground.swift
//  CrewClock
//
//  Created by Edgars Yarmolatiy on 7/31/25.
//

import SwiftUI

struct TwoCirclesBackground: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(
                    .linearGradient(colors: [
                        .red,
                        .blue
                    ], startPoint: .top, endPoint: .bottom)
                )
                .frame(width: 140, height: 140)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .offset(x: -25, y: -55)
            
            Circle()
                .fill(
                    .linearGradient(colors: [
                        .yellow,
                        .green
                    ], startPoint: .top, endPoint: .bottom)
                )
                .frame(width: 140, height: 140)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                .offset(x: 25, y: 55)
        }
    }
}

#Preview {
    TwoCirclesBackground()
}
