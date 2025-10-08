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
