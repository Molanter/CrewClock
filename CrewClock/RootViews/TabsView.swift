//
//  TabsView.swift
//  CrewClock
//
//  Created by Edgars Yarmolatiy on 6/4/25.
//

import SwiftUI

struct TabsView: View {
    @State var selection: Int = 0
    
    init() {
        let tabBarAppearance = UITabBar.appearance()
        tabBarAppearance.backgroundColor = UIColor.systemGray6
    }
    
    var body: some View {
        TabView(selection: $selection) {
            LogsTabView()
                .tabItem {
                    Label("Logs", systemImage: "list.bullet.below.rectangle")
                }
                .tag(0)
                .navigationTitle("Logs")

            ClockTabView()
                .tabItem {
                    Label("Clock", systemImage: "clock")
                }
                .tag(1)

            SettingsTabView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
                .tag(2)
                .navigationTitle("Settings")
        }
    }
}


#Preview {
    TabsView()
}
