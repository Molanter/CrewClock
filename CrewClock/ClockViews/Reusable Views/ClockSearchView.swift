//
//  ClockSearchView.swift
//  CrewClock
//
//  Created by Edgars Yarmolatiy on 7/20/25.
//

import SwiftUI

struct ClockSearchView: View {
    @EnvironmentObject var searchUserViewModel: SearchUserViewModel
    
    @State private var searchText = ""
    
    var body: some View {
        if !searchUserViewModel.foundUIDs.isEmpty {
            List(searchUserViewModel.foundUIDs, id: \.self) { uid in
                UserRowView(uid: uid)
            }
        }
    }
}

//#Preview {
//    ClockSearchView()
//}
