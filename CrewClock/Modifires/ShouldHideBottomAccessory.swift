//
//  ShouldHideBottomAccessory.swift
//  CrewClock
//
//  Created by Edgars Yarmolatiy on 10/27/25.
//

import SwiftUI

struct ShouldHideBottomAccessory: PreferenceKey {
    static let defaultValue = false
    
    static func reduce(value: inout Bool, nextValue: () -> Bool) {
        value = value || nextValue()
    }
}
