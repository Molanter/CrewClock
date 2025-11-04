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
    @EnvironmentObject private var userViewModel: UserViewModel
    @StateObject private var profileCheckVM = ProfileCompletenessViewModel()
    
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
            modernTabsViews
            if publishedVars.navLink.isEmpty {
                VStack(spacing: -10) {
                    if publishedVars.navLink.isEmpty {
                        if activeTab == .logs || activeTab == .settings, !showSearchBar {
                            WorkingFooterView()
                                .padding(.horizontal, K.UI.padding*2)
                        }
                        CustomTabBar(showsSearchBar: true, activeTab: $activeTab, searchText: $publishedVars.searchClock) { status in
                            self.showSearchBar.toggle()
                        } onSearchTextFieldActive: { status in }
                        .padding(.bottom, 10)
                    }
                }
            }
        }
    }
    
    @available(iOS 26.0, *)
    private var tabView: some View {
        TabView(selection: $publishedVars.tabSelected) {
            Tab("Logs", systemImage: "list.bullet.below.rectangle", value: 0) {
                CalendarLogsView()
                    .toolbarVisibility(publishedVars.navLink.isEmpty ? .visible : .hidden, for: .tabBar)
            }
            Tab("Clock", systemImage: "clock", value: 1) {
                ClockTabView()
                    .toolbarVisibility(publishedVars.navLink.isEmpty ? .visible : .hidden, for: .tabBar)
            }
            Tab("Settings", systemImage: "gearshape", value: 2) {
                SettingsTabView()
                    .badge(profileCheckVM.isIncomplete ? "!" : nil)
                    .toolbarVisibility(publishedVars.navLink.isEmpty ? .visible : .hidden, for: .tabBar)
            }
            Tab(value: 3, role: .search) {
                NavigationStack {
                    SearchView()
                        .navigationTitle("Search")
                        .toolbarVisibility(publishedVars.navLink.isEmpty ? .visible : .hidden, for: .tabBar)
                }
                    .searchable(text: $publishedVars.searchClock, placement: .navigationBarDrawer, prompt: "Search People")
                    .onChange(of: publishedVars.searchClock) { oldValue, newValue in
                        searchUserViewModel.searchUsers(with: newValue)
                        print("searchUserViewModel.foundUIDs: -- ", searchUserViewModel.foundUIDs)
                    }
            }
        }
        .onAppear { profileCheckVM.evaluate(with: userViewModel.user) }
        .onChange(of: userViewModel.user?.uid) { _, _ in
            profileCheckVM.evaluate(with: userViewModel.user)
        }
        .tabViewBottomAccessory {
            if publishedVars.navLink.isEmpty {
                WorkingFooterView()
            }
        }
        .tabBarMinimizeBehavior(.onScrollDown)
        .tabViewSearchActivation(.searchTabSelection)
        .toolbar(publishedVars.navLink.isEmpty ? .visible : .hidden, for: .tabBar)

    }
    
    private var modernTabsViews: some View {
        Group {
            if showSearchBar {
                SearchView()
            }else {
                switch activeTab {
                case .logs:
                    CalendarLogsView()
                case .clock:
                    ClockTabView()
                case .tasks:
//                    TasksView()
                    Text("no tasks -_-")
                case .settings:
                    SettingsTabView()
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}


#Preview {
    TabsView()
        .environmentObject(PublishedVariebles())
}
