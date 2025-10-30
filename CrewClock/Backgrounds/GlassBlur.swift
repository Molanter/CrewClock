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
    var blur = 5
    var body: some View {
        TransparentBlurView(removeAllFilters: removeAllFilters)
            .blur(radius: CGFloat(blur), opaque: true)
            .background(colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.1))
    }
}

#Preview {
    GlassBlur()
}
