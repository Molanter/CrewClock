//
//  ProfileView.swift
//  CrewClock
//
//  Created by Edgars Yarmolatiy on 11/1/25.
//

import SwiftUI

struct ProfileView: View {
    @Environment(\.colorScheme) var colorScheme

    let uid: String = ""
    
    private var sheetStrokeColor: Color {
        colorScheme == .dark ? .white.opacity(0.3) : .black.opacity(0.3)
    }
    
    var body: some View {
        NavigationStack {
            list
        }
    }
    
    private var list: some View {
        ScrollView {
            profileHeader
                .padding(.horizontal, K.UI.padding)
            
//            statsScrollBar
//                .padding(.horizontal, K.UI.padding)
            
            mainButtonsRow
                .padding(K.UI.padding)
        }
        .scrollContentBackground(.hidden)
        .background {
//            CarpetBackground()
            DVDScreensaverBackground(
                image: Image("dvd.logo"),
                logoSize: .init(width: 110, height: 80),
                speed: 125,
                background: colorScheme == .dark ? .black : .white,
                useAnimationSchedule: false // true for previews
            )

        }
    }
    
    private var profileHeader: some View {
        VStack(alignment: .leading) {
            HStack {
                profilePicturePart
                Spacer()
            }
            nameRow
            profileHeaderDivider
            descriptionRow
            statsScrollBar
        }
        .padding (K.UI.padding)
        .frame(maxWidth: .infinity)
        .background {
            GlassBlur(removeAllFilters: true, blur: 5)
                .cornerRadius(K.UI.cornerRadius)
                .overlay(
                    RoundedRectangle(cornerRadius: K.UI.cornerRadius)
                        .stroke(sheetStrokeColor, lineWidth: 1.5)
                )
        }
    }
    
    private var profilePicturePart: some View {
        ZStack(alignment: .bottomTrailing) {
//            UserProfileImageCircle(nil)
            Image(systemName: "person.crop.circle")
                .resizable()
                .frame(width: 75, height: 75)
                .clipShape(Circle())
                .shadow(color: shadowColor(), radius: 10)
                .padding(5)
            Image(systemName: "plus")
                .padding(5)
                .background {
                    TransparentBlurView(removeAllFilters: false)
                        .blur(radius: 5, opaque: true)
                        .background(colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.1))
                }
                .clipShape(Circle())
                
        }
    }
    
    private var profileHeaderDivider: some View {
        RoundedRectangle(cornerRadius: 1)
            .frame(height: 1)
            .foregroundStyle(.secondary)
            .padding(5)
    }
    
    private var nameRow: some View {
        Text("David Peterson")
            .font(.title2.bold())
    }
    
    private var descriptionRow: some View {
        Text("Experienced tile specialist focused on high-quality remodeling and detailed finishes.")
            .font(.body)
            .foregroundStyle(.secondary)
    }
    
    private var statsScrollBar: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 10) {
                NavigationLink {
//                    UserConnectionsView()
                    Text("Connections")
                }label: {
                    ProfileStatsView(number: 100, text: "Connections")
                }
                ProfileStatsView(number: 35, text: "Projects")
                ProfileStatsView(number: 30, text: "Clients")

            }
            .buttonStyle(.plain)
            .tint(.primary)
        }
        .scrollIndicators(.hidden)
        .cornerRadius(K.UI.cornerRadius)
    }
    
    private var mainButtonsRow: some View {
        HStack(spacing: 10) {
            Button {
                
            }label: {
                HStack {
                    Image(systemName: /*uid == me ? "pencil" : */"link")
                    Text(/*uid == me ? "Edit Profile" : */"Connect")
                }
                .padding(K.UI.padding)
                .frame(maxWidth: .infinity)
                .frame(height: 45)
                .background(K.Colors.accent)
                .clipShape(Capsule())
            }
            Menu {
                Text("Item 1")
                Text("Item 2")
                Text("Item 3")
            }label: {
                Image(systemName: "ellipsis")
                    .frame(width: 30, height: 30)
//                    .padding()
            }
            .frame(width: 45, height: 45)
            .background {
                TransparentBlurView(removeAllFilters: false)
                    .blur(radius: 5, opaque: true)
                    .background(colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.1))
            }
            .clipShape(Circle())
        }
        .buttonStyle(.plain)
    }
    //MARK: - Functions
    
    private func shadowColor() -> Color {
        return colorScheme == .dark ? Color.black.opacity(0.2) : Color.white.opacity(0.2)
    }
}


// MARK: - Preview
#Preview("Light") {
    ProfileView()
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    ProfileView()
        .preferredColorScheme(.dark)
}
