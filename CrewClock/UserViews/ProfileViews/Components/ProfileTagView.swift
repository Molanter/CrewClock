//
//  ProfileTagView.swift
//  CrewClock
//
//  Created by Edgars Yarmolatiy on 11/4/25.
//

import SwiftUI

struct ProfileTagView: View {
    @Environment(\.colorScheme) var colorScheme
    
    //View Inputs
    var isTag: Bool = false
    var image: String = ""
    var text: String = ""

    private var sheetStrokeColor: Color {
        colorScheme == .dark ? .white.opacity(0.3) : .black.opacity(0.3)
    }
    
    //View Outut
    var body: some View {
        HStack {
            Group {
                if isTag {
                    Text("#\(text.lowercased())")
                }else if image != "", !isTag {
                    HStack {
                        Image(systemName: image)
                        Text(text)
                    }
                }else {
                    Text(text)
                }
            }
                .font(.callout)
                .lineLimit(0)
                .fixedSize(horizontal: true, vertical: true)
        }
        .frame(height: 25)
        .padding(7)
        .background {
            TransparentBlurView(removeAllFilters: false)
                .blur(radius: 5, opaque: true)
                .background(colorScheme == .light ? Color.white.opacity(0.1) : Color.black.opacity(0.1))
                .overlay(
                    Capsule()
                        .stroke(sheetStrokeColor, lineWidth: 1.5)
                )
        }
        .clipShape(Capsule())
    }
}

#Preview {
    ProfileTagView()
}
