//
//  AssigneeStatusAvatar.swift
//  CrewClock
//
//  Created by Edgars Yarmolatiy on 11/15/25.
//

import SwiftUI

struct AssigneeStatusAvatar: View {
    @Environment(\.colorScheme) var colorScheme

    let uid: String
    let status: String
    let size: CGFloat
    
    private var blurColor: Color {
        colorScheme == .dark ? .white.opacity(0.3) : .black.opacity(0.3)
    }

    private var statusIcon: String {
        switch status.lowercased() {
        case "rejected":
            return "xmark"
        case "accepted":
            return "checkmark"
        case "done":
            return "flag.checkered"
        case "sent":
            return "paperplane.fill"
        case "seen":
            return "eye.fill"
        default:
            return "paperplane.fill"
        }
    }

    private var statusColor: Color {
        switch status.lowercased() {
        case "rejected":
            return .red
        case "accepted":
            return .green
        case "done":
            return .primary
        case "sent", "seen":
            return .secondary
        default:
            return .secondary
        }
    }
    
    private func shadowColor() -> Color {
        colorScheme == .dark ? Color.black.opacity(0.2) : Color.white.opacity(0.2)
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            // Main avatar
            UserAvatarFromUID(uid: uid)
                .frame(width: size, height: size)
                .clipShape(Circle())
                .shadow(color: shadowColor(), radius: 10)


            // Status badge in bottom-right corner with blurred background
            Image(systemName: statusIcon)
                .resizable()
                .frame(width: size/4, height: size/4)
                .padding(5)
                .background {
                    TransparentBlurView(removeAllFilters: false)
                        .blur(radius: 5, opaque: true)
                        .background(colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.1))
                }
                .clipShape(Circle())
                .foregroundStyle(statusColor)
                .offset(x: 5)
        }
        .padding(.bottom, K.UI.padding/2)
    }
}


struct AssigneeStatusScrollView: View {
    let task: TaskFB
    var size: CGFloat = 52
    var spacing: CGFloat = 12

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: spacing) {
                ForEach(Array(task.assigneeUserUIDs.enumerated()), id: \.offset) { _, uid in
                    let status = task.assigneeStates[uid] ?? "pending"
                    AssigneeStatusAvatar(uid: uid, status: status, size: size)
                }
            }
            .padding(.horizontal, 4)
        }
    }
}
