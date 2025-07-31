//
//  Test.swift
//  CrewClock
//
//  Created by Edgars Yarmolatiy on 7/30/25.
//

import SwiftUI

struct Test: View {
    var body: some View {
        TabView {
            Text("First")
            Text("Second")
            Text("Third")
        }
        .tabViewStyle(.page(indexDisplayMode: .always))
    }
}

#Preview {
    Test()
}
