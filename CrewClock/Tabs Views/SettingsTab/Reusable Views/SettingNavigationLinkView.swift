//
//  SettingNavigationLinkView.swift
//  CrewClock
//
//  Created by Edgars Yarmolatiy on 10/6/25.
//

import SwiftUI

struct SettingNavigationLinkView: View {
    let type: SettingsNavigationLinks
    
    var body: some View {
        link
    }
    
    private var link: some View {
        NavigationLink {
            if type == .deleteAccount {
                DeleteAccountView().environmentObject(AccountDeletionViewModel()).environmentObject(AuthViewModel())
                    .hideTabBarWhileActive(type.title)
            }else {
                type.destination
                    .hideTabBarWhileActive(type.title)
            }
        }label: {
            linkLabel
        }
    }
    
    private var linkLabel: some View {
        HStack {
            iconStack
            Text(type.title)
                .foregroundStyle(Color.primary)
            Spacer()
        }
    }
    
    private var iconStack: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(type.color)
                .frame(width: 30, height: 30)
            Image(systemName: type.image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 20, height: 20)
                .foregroundStyle(Color.white)
        }
    }
}

#Preview {
    SettingNavigationLinkView(type: .about)
}
