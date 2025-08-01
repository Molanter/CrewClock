//
//  GlassBlur.swift
//  CrewClock
//
//  Created by Edgars Yarmolatiy on 7/31/25.
//

import SwiftUI

struct GlassBlur: View {
    @Environment(\.colorScheme) var colorScheme
    var removeAllFilters: Bool = false
    var blur = 0.05
    var body: some View {
        TransparentBlurView(removeAllFilters: removeAllFilters)
            .blur(radius: 9, opaque: true)
            .background(colorScheme == .dark ? Color.white.opacity(blur) : Color.black.opacity(0.1))
    }
}

#Preview {
    GlassBlur()
}
