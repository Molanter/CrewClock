//
//  PublishedVariebles.swift
//  CrewClock
//
//  Created by Edgars Yarmolatiy on 7/14/25.
//


import SwiftUI

class PublishedVariebles: ObservableObject {
    @Published var searchLog = ""
    @Published var searchClock = ""

    @Published var tabSelected = 0
    
    //MARK: Variables
//    func getUser(_ uid: String) -> UserFB? {
//        userViewModel.getUser(uid)
//    }

    
}
