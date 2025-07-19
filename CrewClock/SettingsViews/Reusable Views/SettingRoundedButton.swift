//
//  SettingRoundedButton.swift
//  CrewClock
//
//  Created by Edgars Yarmolatiy on 6/12/25.
//

import SwiftUI

struct SettingRoundedButton: View {
    var image: Bool
    var text1: String
    var text2: String
    
    var body: some View {
        VStack {
            if image {
                Image(systemName: "")
                Text(text2)
            }else {
                Text(text1)
                Text(text2)
            }
        }
        .padding(10)
        .frame(height: 75)
        .background {
            RoundedRectangle(cornerRadius: K.UI.cornerRadius)
                .fill(Color.listRow)
        }
    }
}

#Preview {
    SettingRoundedButton(image: false, text1: "Connections", text2: "89")
}
