//
//  SignInButtonView.swift
//  CrewClock
//
//  Created by Edgars Yarmolatiy on 7/31/25.
//

import SwiftUI

struct SignInButtonView: View {
    let text: String
    let image: String
    let colored: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Group {
                if image == "google.g.logo" {
                    HStack {
                        Image(image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 20)
                        Text(text)
                    }
                } else {
                    Label(text, systemImage: image)
                }
            }
            .padding(K.UI.padding)
            .frame(maxWidth: .infinity)
            .background {
                if colored {
                    RoundedRectangle(cornerRadius: K.UI.cornerRadius)
                        .fill(K.Colors.accent)
                } else {
//                    TransparentBlurView(removeAllFilters: false)
//                        .blur(radius: 9, opaque: true)
//                        .background(.white.opacity(0.05))
                    GlassBlur(removeAllFilters: false)
                        .cornerRadius(K.UI.cornerRadius)
                }
            }
        }
        .buttonStyle(.plain)
    }
}
