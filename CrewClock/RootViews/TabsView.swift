//
//  TabsView.swift
//  CrewClock
//
//  Created by Edgars Yarmolatiy on 6/4/25.
//

import SwiftUI

struct TabsView: View {
    @EnvironmentObject var publishedVars: PublishedVariebles
    @EnvironmentObject var searchUserViewModel: SearchUserViewModel

    init() {
        let tabBarAppearance = UITabBar.appearance()
        tabBarAppearance.backgroundColor = UIColor.systemGray6
    }
    
    var body: some View {
        TabView(selection: $publishedVars.tabSelected) {
            log

            clock

            settings
        }
    }
    
    private var log: some View {
        LogsTabView()
            .searchable(text: $publishedVars.searchLog, placement: .navigationBarDrawer, prompt: "Search logs")
            .tabItem {
                Label("Logs", systemImage: "list.bullet.below.rectangle")
            }
            .tag(0)
            .navigationTitle("Logs")
    }
    
    private var clock: some View {
        ClockTabView()
            .searchable(text: $publishedVars.searchClock, placement: .navigationBarDrawer, prompt: "Search People")
            .onChange(of: publishedVars.searchClock) { oldValue, newValue in
                searchUserViewModel.searchUsers(with: newValue)
                print("searchUserViewModel.foundUIDs: -- ", searchUserViewModel.foundUIDs)
            }
            .tabItem {
                Label("Clock", systemImage: "clock")
            }
            .tag(1)
    }
    
    private var settings: some View {
        SettingsTabView()
            .tabItem {
                Label("Settings", systemImage: "gearshape")
            }
            .tag(2)
            .navigationTitle("Settings")
    }
}


#Preview {
    TabsView()
}
