//
//  ContentView.swift
//  CrewClock
//
//  Created by Edgars Yarmolatiy on 5/27/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var authViewModel = AuthViewModel()
    @StateObject private var sheetViewModel = SpreadSheetViewModel()
    var body: some View {
        RootView()
            .environmentObject(authViewModel)
            .environmentObject(sheetViewModel)
    }
}

#Preview {
    ContentView()
}
