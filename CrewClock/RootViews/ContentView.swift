//
//  ContentView.swift
//  CrewClock
//
//  Created by Edgars Yarmolatiy on 5/27/25.
//

import SwiftUI

struct ContentView: View {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    
    var body: some View {
        if hasSeenOnboarding{
            RootView()
                .accentColor(K.Colors.accent)
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
