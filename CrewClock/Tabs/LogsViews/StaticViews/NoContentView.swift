//
//  NoContentView.swift
//  CrewClock
//
//  Created by Edgars Yarmolatiy on 7/20/25.
//

import SwiftUI

struct NoContentView: View {
    @State var showAddLog = false
    
    var contentType: NoContentType = .noLogs
    
    var body: some View {
        page
            .sheet(isPresented: $showAddLog) {
                AddLogView(showAddLogSheet: $showAddLog)
                    .tint(K.Colors.accent)
            }
    }
    
    private var page: some View {
        VStack {
            if contentType == .noLogs {
                Spacer()
            }
            gifPart
            textPart
            if contentType == .noLogs {
                Spacer()
                button
            }
        }
    }
    
    private var gifPart: some View {
        Group {
            if let gifURL = contentType.gif {
                GIFImageView(url: gifURL)
                    .frame(width: 200)
            } else {
                ProgressView()
            }
        }
    }
    
    private var textPart: some View {
        VStack {
            Text(contentType.title)
                .font(.title)
                .bold()
            Text(contentType.subtitle)
                .foregroundStyle(.secondary)
        }
    }
    
    private var button: some View {
        Button {
            self.showAddLog.toggle()
        } label: {
            Text("Add Log")
                .bold()
                .padding(K.UI.padding * 2)
                .background {
                    RoundedRectangle(cornerRadius: K.UI.cornerRadius)
                        .fill(K.Colors.accent)
                }
                .padding(.bottom)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NoContentView()
}
