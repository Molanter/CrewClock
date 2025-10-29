//
//  View.swift
//  CrewClock
//
//  Created by Edgars Yarmolatiy on 10/7/25.
//

import SwiftUI


extension View {
    /// Marks this view as an "active navigation destination" with the given key.
    /// While active, set `PublishedVariebles.navLink` to `key`; clear on disappear.
    /// Use this with a top-level `.toolbarVisibility(pub.navLink.isEmpty ? .visible : .hidden, for: .tabBar)`
    /// inside your TabView content.
    func hideTabBarWhileActive(_ key: String) -> some View {
        modifier(HideTabBarWhileActive(key: key))
    }
}

// MARK: - Hide tab bar while a destination is active (iOS 17+ compatible)

struct HideTabBarWhileActive: ViewModifier {
    @EnvironmentObject private var pub: PublishedVariebles
    let key: String
    @State private var didSetKey = false

    func body(content: Content) -> some View {
        content
            .onAppear {
                // Avoid re-entrant layout loops by only setting once per lifetime
                guard !didSetKey else { return }
                didSetKey = true
                if pub.navLink != key {
                    // Defer to next runloop to avoid immediate layout invalidation during mount
                    DispatchQueue.main.async {
                        pub.navLink = key
                    }
                }
            }
            .onDisappear {
                // Only clear if we were the one that set it (and still current)
                if didSetKey && pub.navLink == key {
                    pub.navLink = ""
                }
                didSetKey = false
            }
        // Hiding bottom accesory 
            .preference(key: ShouldHideBottomAccessory.self, value: true)
    }
}
