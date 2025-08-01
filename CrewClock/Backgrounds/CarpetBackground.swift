//
//  CarpetBackground.swift
//  CrewClock
//
//  Created by Edgars Yarmolatiy on 7/31/25.
//

import SwiftUI

struct CarpetBackground: View {
    var body: some View {
        Color.clear.overlay(
            Image("carpet")
                .resizable()
                .aspectRatio(contentMode: .fill)
        )
        .edgesIgnoringSafeArea(.all)
    }
}

#Preview {
    CarpetBackground()
}
