//
//  VisualEffectBlur.swift
//  CrewClock
//
//  Created by Edgars Yarmolatiy on 9/19/25.
//


import SwiftUI
import UIKit

/// UIKit blur bridged into SwiftUI
struct VisualEffectBlur: UIViewRepresentable {
    let style: UIBlurEffect.Style

    func makeUIView(context: Context) -> UIVisualEffectView {
        UIVisualEffectView(effect: UIBlurEffect(style: style))
    }
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {}
}

/// Drop-in row background with blur + rounded corners
struct BlurRowBackground: View {
    var cornerRadius: CGFloat = 12
    var blurStyle: UIBlurEffect.Style = .systemUltraThinMaterial
    var overlayOpacity: CGFloat = 0.08   // subtle tint; set to 0 for pure blur

    var body: some View {
        VisualEffectBlur(style: blurStyle)
            .background(Color.primary.opacity(overlayOpacity)) // faint tint over blur
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
}