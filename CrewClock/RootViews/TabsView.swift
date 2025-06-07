//
//  TabView.swift
//  CrewClock
//
//  Created by Edgars Yarmolatiy on 6/4/25.
//

import SwiftUI

struct TabView: View {
    @State var selection: Int = 0
    
    var body: some View {
        NavigationStack {
            TabView(selection: $selection) {
                LogsTabView()
                    .tabItem {
                        Label("Logs", systemImage: "list.bullet.below.rectangle")
                    }
                    .tag(0)

                LogsTabView()
                    .tabItem {
                        Label("Clock", systemImage: "clock")
                    }
                    .tag(1)

                LogsTabView()
                    .tabItem {
                        Label("Settings", systemImage: "gearshape")
                    }
                    .tag(2)
            }
        }
    }
}


#Preview {
    TabView()
}
