//
//  UserRowList.swift
//  CrewClock
//
//  Created by Edgars Yarmolatiy on 7/29/25.
//

import SwiftUI

struct UserRowList: View {
    var uids: [String]
    
    var body: some View {
        list
    }
    
    private var list: some View {
        List(uids, id: \.self) { uid in
            UserRowView(uid: uid)
        }
    }
}

#Preview {
    UserRowList(uids: [
        "uid123",
        "uid456",
        "uid789"
    ])
}
