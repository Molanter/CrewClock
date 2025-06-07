//
//  LogsTabView.swift
//  CrewClock
//
//  Created by Edgars Yarmolatiy on 6/2/25.
//

import SwiftUI

struct LogsTabView: View {
    var body: some View {
        NavigationView {
            list
            .navigationTitle("Logs")
        }
    }
    
    var list: some View {
        VStack {
            List {
                logItem
    //                ForEach(sampleLogs, id: \.self) { log in
    //                    VStack(alignment: .leading) {
    //                        Text(log.title)
    //                            .font(.headline)
    //                        Text(log.message)
    //                            .font(.subheadline)
    //                            .foregroundColor(.gray)
    //                    }
    //                    .padding(.vertical, 4)
    //                }
            }
            footer
        }
        .background(Color(.systemGray6))
    }
    
    var logItem: some View {
        VStack(alignment: .leading) {
            HStack(alignment: .center) {
                VStack(alignment: .leading) {
                    Text("✅ " + "May 26, 2025")
                        .font(.footnote)
                    Text("8:00AM - 3:00PM")
                        .font(.callout)
                        .bold()
                }
                Spacer()
                projectsMenu

            }
            Text("Framed kitchen walls")
                .font(.callout)
                .foregroundStyle(.secondary)
        }
    }
    
    var projectsMenu: some View {
        Menu {
            Button {
                print("Jordan's kitchen")
            } label: {
                Text("Jordan's kitchen")
            }

        } label: {
            HStack {
                Text("Jordan's kitchen")
                    .font(.callout)
                    .lineLimit(1)
                Image(systemName: "chevron.down")
            }
            .foregroundStyle(Color(.cyan))
            .padding(7)
            .background {
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color(.cyan))
                    .opacity(0.5)
            }
        }
    }
    
    var footer: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("Today's time: ") + Text("8:00AM Clocked In").bold()                        .font(.callout)
                HStack(alignment: .center) {
                    Text("Working on: ")
                        .font(.callout)
                        .bold()
                    projectsMenu
                }
            }
            .padding(15)
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .background {
            Rectangle()
                .fill(Color(.white))
                .cornerRadius(20, corners: [.topLeft, .topRight])
        }

    }
}

struct LogEntry: Hashable {
    let title: String
    let message: String
}

let sampleLogs: [LogEntry] = [
    LogEntry(title: "✅ Success", message: "Spreadsheet ID submitted to Firebase."),
    LogEntry(title: "❌ Error", message: "Missing or insufficient permissions."),
    LogEntry(title: "ℹ️ Info", message: "Firestore write completed."),
    LogEntry(title: "⚠️ Warning", message: "Sheet1!A1 range not found.")
]

#Preview {
    LogsTabView()
}


extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}
