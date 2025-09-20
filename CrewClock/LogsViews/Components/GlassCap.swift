//
//  GlassCap.swift
//  CrewClock
//
//  Created by Edgars Yarmolatiy on 9/20/25.
//


import SwiftUI

struct OutsideGlassOverlay: View {
    var radius: CGFloat = K.UI.cornerRadius

    var body: some View {
        TransparentBlurView(removeAllFilters: false)
            .blur(radius: 0, opaque: true)
            .background(.white.opacity(0.1))
            .inverseMask {
                // The CLEAR window (your content) — rest stays blurred
                UnevenRoundedRectangle(
                    topLeadingRadius: radius, bottomLeadingRadius: 0,
                    bottomTrailingRadius: 0, topTrailingRadius: radius,
                    style: .continuous
                )
                .fill(style: FillStyle(eoFill: false))
            }
            .allowsHitTesting(false)
    }
}

extension View {
    /// Masks the *inverse* of `mask`: keeps the outside, cuts out the mask's shape.
    func inverseMask<Mask: View>(@ViewBuilder _ mask: () -> Mask) -> some View {
        self.mask {
            Rectangle()
                .overlay(mask().blendMode(.destinationOut))
                .compositingGroup()
        }
    }
}
