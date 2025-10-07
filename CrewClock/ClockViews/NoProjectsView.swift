//
//  NoProjectsView.swift
//  CrewClock
//
//  Created by Edgars Yarmolatiy on 7/20/25.
//


import SwiftUI

struct NoProjectsView: View {
    var contentType: EmptyProjectStateType = .noActiveProjects
    
    var body: some View {
        HStack(spacing: 8) {
            gifPart
            Text(contentType.text)
                .font(.headline)
                .foregroundColor(.secondary)
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical)
    }
    
    private var gifPart: some View {
        Group {
            if let gifURL = contentType.gif {
                GIFImageView(url: gifURL)
                    .frame(width: 50)
            } else {
                ProgressView()
            }
        }
    }
}

#Preview {
    NoProjectsView(contentType: .noActiveProjects)
}
