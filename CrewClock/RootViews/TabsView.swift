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

    @State private var activeTab: TabItem = .clock
    @State private var showSearchBar: Bool = false
    
    init() {
        let tabBarAppearance = UITabBar.appearance()
        tabBarAppearance.backgroundColor = UIColor.systemGray6
    }
    
    var body: some View {
        
        ZStack(alignment: .bottom) {
            Group {
                if showSearchBar {
                    ClockSearchView()
                }else {
                    switch activeTab {
                    case .logs:
                        LogsTabView()
                            .searchable(text: $publishedVars.searchLog, placement: .navigationBarDrawer, prompt: "Search logs")
                    case .clock:
                        ClockTabView()
                            .searchable(text: $publishedVars.searchClock, placement: .navigationBarDrawer, prompt: "Search People")
                            .onChange(of: publishedVars.searchClock) { oldValue, newValue in
                                searchUserViewModel.searchUsers(with: newValue)
                                print("searchUserViewModel.foundUIDs: -- ", searchUserViewModel.foundUIDs)
                            }
                    case .settings:
                        SettingsTabView()
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            VStack {
                if activeTab == .logs || activeTab == .clock {
                    WorkingFooterView()
                        .padding(.horizontal, K.UI.padding*2)
                }
                CustomTabBar(showsSearchBar: true, activeTab: $activeTab, searchText: $publishedVars.searchClock) { status in
                    self.showSearchBar.toggle()
                } onSearchTextFieldActive: { status in
                }
                .padding(.bottom, 10)
            }
        }
        
//        TabView(selection: $publishedVars.tabSelected) {
//            log
//
//            clock
//
//            settings
//        }
    }
    
    private var log: some View {
        LogsTabView()
            .searchable(text: $publishedVars.searchLog, placement: .navigationBarDrawer, prompt: "Search logs")
            .tabItem {
                Label("Logs", systemImage: "list.bullet.below.rectangle")
            }
            .tag(0)
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
    }
}


#Preview {
    TabsView()
        .environmentObject(PublishedVariebles())
}
