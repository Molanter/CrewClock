//
//  ListExtention.swift
//  CrewClock
//
//  Created by Edgars Yarmolatiy on 9/19/25.
//

import SwiftUI

/// A skinnable List replacement that preserves Sections.
public struct GlassList<Content: View>: View {
    
    // Builders
    @ViewBuilder let content: () -> Content
    
    public var body: some View {
        
        // The actual List with your defaults
        List {
            content()
//                .listRowBackground(
//                    TransparentBlurView(removeAllFilters: false)
//                        .blur(radius: 9, opaque: true)
//                        .background(.white.opacity(0.1))
//                )
        }
//        .background {
//            ListBackground()
//                .ignoresSafeArea()   // under status/nav/tab bars
//        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .scrollDismissesKeyboard(.interactively) // restore keyboard handling
    }
}

// MARK: - Internal helpers
private struct ListStyleModifier: ViewModifier {
    let useInsetGrouped: Bool
    func body(content: Content) -> some View {
        if useInsetGrouped {
            content.listStyle(.insetGrouped)
        } else {
            content.listStyle(.plain)
        }
    }
}

private struct SectionSpacingModifier: ViewModifier {
    let value: CGFloat?
    func body(content: Content) -> some View {
        if let v = value, #available(iOS 17.0, *) {
            content.listSectionSpacing(v)
        } else {
            content
        }
    }
}
