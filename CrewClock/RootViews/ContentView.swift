//
//  ContentView.swift
//  CrewClock
//
//  Created by Edgars Yarmolatiy on 5/27/25.
//

import SwiftUI

struct ContentView: View {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
        
    init() {
            // Make List use our own container background (optional):
            UITableView.appearance().backgroundColor = .clear

            // Default row background for every List row:
            UITableViewCell.appearance().backgroundColor = UIColor.systemBackground
        }
    
    var body: some View {
        if hasSeenOnboarding{
            ToastNavigationView {
                RootView()
                    .accentColor(K.Colors.accent)
                    .tint(K.Colors.accent)
            }
        }else {
            OnboardingView(
                isShowing: Binding(
                    get: { !hasSeenOnboarding },
                    set: { newValue in hasSeenOnboarding = !newValue }
                )
            )
        }
    }
}

#Preview {
    ContentView()
}
