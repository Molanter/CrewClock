//
//  StretchyHeader.swift
//  CrewClock
//
//  Created by Edgars Yarmolatiy on 9/24/25.
//

import SwiftUI

struct StretchyHeader: View {
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject private var userViewModel: UserViewModel
    
    @StateObject private var teamsVM = CreateTeamViewModel()
    
    let color: Color
    let image: String
    let teamId: String
    let height: CGFloat
    let canManageMembers: Bool
    
    var body: some View {
        GeometryReader { geo in
            let y = geo.frame(in: .global).minY
            let stretch = max(0, y)
            
            ZStack(alignment: .bottom) {
                Rectangle()
                    .fill(color)
                    .clipShape(
                        UnevenRoundedRectangle(
                            topLeadingRadius: 0,
                            bottomLeadingRadius: K.UI.cornerRadius,
                            bottomTrailingRadius: K.UI.cornerRadius,
                            topTrailingRadius: 0,
                            style: .continuous
                        )
                    )
                    .frame(height: height + stretch)
                    .ignoresSafeArea(edges: .top)
                
                if canManageMembers {
                    imageButton
                }else {
                    imageSection
                }
            }
            .offset(y: -stretch) // <- cancels scroll-down drift
        }
        .frame(height: height)
    }
    
    private func blurColor() -> Color {
        return colorScheme == .dark ? Color.black : Color.white
    }
    
    private var imageButton: some View {
        Menu {
            colorMenu
            iconMenu
        }label: {
            imageSection
        }
    }
    
    private var imageSection: some View {
        ZStack {
            TransparentBlurView(removeAllFilters: false)
                .blur(radius: 9, opaque: true)
                .background(blurColor().opacity(0.1))
                .frame(width: 100, height: 100)
                .cornerRadius(K.UI.cornerRadius)
            imageSymbol()
        }
        .offset(y: 50)
    }
    
    private var colorMenu: some View {
        Menu {
            ForEach(K.Colors.teamColors, id:\.self) { color in
                Button {
                    updateColor(color)
                }label: {
                    HStack {
                        Circle()
                            .fill(color)
                        Text(K.Colors.colorName(color))
                    }
                }
            }
        }label: {
            Label("Change color", systemImage: "paintpalette")
        }
    }
    
    private var iconMenu: some View {
        Menu {
            ForEach(K.SFSymbols.teamArray, id: \.self) { symbol in
                Button {
                    updateIcon(symbol)
                }label: {
                    imageIcon(symbol)
                    Spacer()
                    if symbol == image{
                        Image(systemName: "checkmark")
                    }
                }
            }
        }label: {
            Label("Change an Icon", systemImage: "photo.circle")
        }
    }
    
    //MARK: Functions
    
    @ViewBuilder
    private func imageIcon(_ symbol: String) -> some View {
        Image(systemName: symbol)
            .resizable()
            .scaledToFit()
            .frame(width: 30, height: 30)
            .padding(8)
            .background(symbol == image ? K.Colors.accent.opacity(0.2) : Color.clear)
            .cornerRadius(8)
    }
    
    @ViewBuilder
    private func imageSymbol() -> some View {
        Image(systemName: image)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(height: 75)
            .foregroundStyle(color)
            .brightness(colorScheme == .light ? -0.1 : 0.1)
    }
    
    private func updateColor(_ newColor: Color) {
        Task {
            _ = await teamsVM.updateTeam(teamId: teamId, color: newColor)
        }
    }
    
    private func updateIcon(_ newSymbol: String) {
        Task {
            _ = await teamsVM.updateTeam(teamId: teamId, image: newSymbol)
        }
    }
}

//#Preview {
//    ManageTeamView(team: .init(
//        id: "",
//        name: "Team Name",
//        ownerUid: "",
//        members: [
//            TeamMemberEntry(uid: "v51yL1dwlQWFCAGfMWPuvpVUUXl1", role: .owner),
//            TeamMemberEntry(uid: "8wsO3dRoOaddUm6fJbRVS9JhWQv2", role: .admin),
//            TeamMemberEntry(uid: "zDtFx2cgaUcLf4XWjbVuEf6Y34v1", role: .member),
//            TeamMemberEntry(uid: "1hFLgF40QDfjhvcgJ7L06H5t4nS2", role: .member),
//            TeamMemberEntry(uid: "s3KpZYX3b8ZuOWmSz1hoTeB2XXC3", role: .member),
//        ],
//        image: "hammer",
//        color: .indigo
//    ))
//    .colorScheme(.dark)
//}

