//
//  PublishedVariebles.swift
//  CrewClock
//
//  Created by Edgars Yarmolatiy on 7/14/25.
//


import SwiftUI

class PublishedVariebles: ObservableObject {
    @Published var navLink: String = ""
    
    //MARK: Search Variables
    @Published var searchLog = ""
    @Published var searchClock = ""
    @Published var userSearch = ""

    @Published var tabSelected = 1
    
    //MARK: Variables
//    func getUser(_ uid: String) -> UserFB? {
//        userViewModel.getUser(uid)
//    }

    
}
