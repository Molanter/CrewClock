//
//  ProjectsMenuView.swift
//  CrewClock
//
//  Created by Edgars Yarmolatiy on 6/2/25.
//

import SwiftUI

struct ProjectsMenuView: View {
    @Binding var selected: String
    var projects: [String]

    var body: some View {
        Menu {
            ForEach(projects, id:\.self){ project in
                Button {
                    print(project)
                    self.selected = project
                } label: {
                    Text(project)
                }
            }

        } label: {
            label
        }
    }
    
    var label: some View {
        HStack {
            Text(selected)
                .font(.callout)
                .lineLimit(1)
            Image(systemName: "chevron.down")
        }
        .foregroundStyle(Color(.cyan))
        .padding(7)
        .background {backGround}
    }
    
    var backGround: some View {
        RoundedRectangle(cornerRadius: 15)
            .fill(Color(.cyan))
            .opacity(0.5)
    }
}

//#Preview {
//    ProjectsMenuView()
//}
