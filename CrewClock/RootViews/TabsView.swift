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
    
    @Environment(\.isSearching) var isSearching
    
    @State private var activeTab: TabItem = .clock
    @State private var showSearchBar: Bool = false
    
    init() {
        if #unavailable(iOS 26.0, ) {
            let tabBarAppearance = UITabBar.appearance()
            tabBarAppearance.backgroundColor = UIColor.systemGray6
        }
    }
    
    var body: some View {
        
        if #available(iOS 26.0, *) {
           tabView
        } else {
            modernTabs
        }
    }
    
    //MARK: Different TabView Look (like iOS26)
    private var modernTabs: some View {
        ZStack(alignment: .bottom) {
            Group {
                if showSearchBar {
                    SearchView()
                }else {
                    switch activeTab {
                    case .logs:
//                        LogsTabView()
                        CalendarLogsView()
//                            .searchable(text: $publishedVars.searchLog, placement: .navigationBarDrawer, prompt: "Search logs")
                    case .clock:
                        ClockTabView()
                    case .settings:
                        SettingsTabView()
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            VStack(spacing: -10) {
                if activeTab == .logs || activeTab == .settings, !showSearchBar {
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
    }
    
    @available(iOS 26.0, *)
    private var tabView: some View {
        TabView(selection: $publishedVars.tabSelected) {
            Tab("Logs", systemImage: "list.bullet.below.rectangle", value: 0) {
                CalendarLogsView()
//                    .searchable(text: $publishedVars.searchLog, placement: .navigationBarDrawer, prompt: "Search logs")
            }
            Tab("Clock", systemImage: "clock", value: 1) {
                ClockTabView()
            }
            Tab("Settings", systemImage: "gearshape", value: 2) {
                SettingsTabView()
            }
            Tab(value: 3, role: .search) {
                NavigationStack {
                    SearchView()
                        .navigationTitle("Search")
                }
                    .searchable(text: $publishedVars.searchClock, placement: .navigationBarDrawer, prompt: "Search People")
                    .onChange(of: publishedVars.searchClock) { oldValue, newValue in
                        searchUserViewModel.searchUsers(with: newValue)
                        print("searchUserViewModel.foundUIDs: -- ", searchUserViewModel.foundUIDs)
                    }
            }
        }
        .tabViewBottomAccessory {
            WorkingFooterView()
        }
        .tabBarMinimizeBehavior(.onScrollDown)
    }
    
//    //MARK: Tab Items
//    private var log: some View {
//        LogsTabView()
//            .searchable(text: $publishedVars.searchLog, placement: .navigationBarDrawer, prompt: "Search logs")
//    }
//    
//    private var clock: some View {
//        ClockTabView()
//    }
//    
//    private var settings: some View {
//        SettingsTabView()
//    }
    
//    @available(iOS 26, *)
//    private var search: some View {
//        Tab("Search", systemImage: "magnifyingglass", role: .search) {
//            ClockSearchView()
//                .searchable(text: $publishedVars.searchClock, placement: .navigationBarDrawer, prompt: "Search People")
//                .onChange(of: publishedVars.searchClock) { oldValue, newValue in
//                    searchUserViewModel.searchUsers(with: newValue)
//                    print("searchUserViewModel.foundUIDs: -- ", searchUserViewModel.foundUIDs)
//                }
//        }
//    }
}

//@SceneStorage("selectedTab") private var selectedTab = 0

#Preview {
    TabsView()
        .environmentObject(PublishedVariebles())
}

