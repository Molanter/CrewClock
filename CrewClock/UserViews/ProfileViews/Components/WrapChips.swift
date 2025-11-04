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
        var width: CGFloat = 0
        var height: CGFloat = 0

        return GeometryReader { geo in
            ZStack(alignment: .topLeading) {
                ForEach(items, id: \.self) { item in
                    chip(item)
                        .padding(4)
                        .alignmentGuide(.leading) { d in
                            if abs(width - d.width) > geo.size.width {
                                width = 0
                                height -= d.height
                            }
                            let result = width
                            if item == items.last { width = 0 }
                            width += d.width
                            return result
                        }
                        .alignmentGuide(.top) { _ in
                            let result = height
                            if item == items.last { height = 0 }
                            return result
                        }
                }
            }
        }.frame(minHeight: 44)
    }
}
