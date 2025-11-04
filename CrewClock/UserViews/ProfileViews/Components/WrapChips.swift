//
//  WrapChips.swift
//  CrewClock
//
//  Created by Edgars Yarmolatiy on 11/4/25.
//

import SwiftUI


struct WrapChips<Content: View>: View {
    let items: [String]
    let chip: (String) -> Content

    init(items: [String], @ViewBuilder chip: @escaping (String) -> Content) {
        self.items = items
        self.chip = chip
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 8) {
                ForEach(items, id: \.self) { item in
                    chip(item)
                        .padding(4)
                }
            }
        }
        .frame(maxHeight: 60)
    }
}
