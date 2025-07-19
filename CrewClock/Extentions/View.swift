//
//  View.swift
//  CrewClock
//
//  Created by Edgars Yarmolatiy on 6/7/25.
//

import SwiftUI

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}
