//
//  SettingRoundedButton.swift
//  CrewClock
//
//  Created by Edgars Yarmolatiy on 6/12/25.
//

import SwiftUI

struct SettingRoundedButton: View {
    var image: Bool
    var text1: String
    var text2: String
    
    var body: some View {
        VStack {
            if image {
                Image(systemName: text1)
                Text(text2)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }else {
                Text(text2)
                Text(text1)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(10)
        .frame(height: 75)
        .background {
            Color.listRow
//            TransparentBlurView(removeAllFilters: false)
//                .blur(radius: 9, opaque: true)
//                .background(.white.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: K.UI.cornerRadius, style: .continuous))
        }
    }
}

#Preview {
    SettingRoundedButton(image: false, text1: "Connections", text2: "89")
}
