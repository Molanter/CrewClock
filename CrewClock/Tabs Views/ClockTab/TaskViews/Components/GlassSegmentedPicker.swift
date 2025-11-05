//
//  GlassSegmentedPicker.swift
//  CrewClock
//
//  Created by Edgars Yarmolatiy on 10/21/25.
//

import SwiftUI

struct IconTextSegmentedPicker<ID: Hashable & Identifiable>: View {
    struct Item: Identifiable, Hashable {
        let id: ID
        let title: String
        let systemImage: String
    }

    @Binding var selection: ID
    let items: [Item]

    var height: CGFloat = 34
    var normalText: Color = .secondary
    var selectedText: Color = .primary

    @Namespace private var ns

    var body: some View {
        content
            .animation(.snappy(duration: 0.22), value: selection)
    }

    @ViewBuilder
    private var content: some View {
        HStack(spacing: 6) {
            ForEach(items) { item in
                segment(for: item)
            }
        }
        .padding(6)
        .frame(height: height + 12)
        .background(Color.clear)
        .overlay(
            RoundedRectangle(cornerRadius: height / 2, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.08), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: height / 2, style: .continuous))
    }

    @ViewBuilder
    private func segment(for item: Item) -> some View {
        Button {
            withAnimation(.snappy(duration: 0.24)) {
                selection = item.id
            }
        } label: {
            ZStack {
                selectionBackground(item.id == selection)
                segmentLabel(item)
            }
        }
        .buttonStyle(.plain)
        .frame(height: height)
        .contentShape(Rectangle())
        .accessibilityLabel(Text(item.title))
    }

    @ViewBuilder
    private func selectionBackground(_ isSelected: Bool) -> some View {
        if isSelected {
            AnyView(
                TransparentBlurView(removeAllFilters: true)
                    .blur(radius: 5, opaque: true)
                    .background(K.Colors.accent.opacity(0.25))
                    .clipShape(Capsule())
                    .matchedGeometryEffect(id: "sel", in: ns)
            )
        }
    }

    private func segmentLabel(_ item: Item) -> some View {
        HStack(spacing: 6) {
            Image(systemName: item.systemImage)
            Text(item.title).lineLimit(1)
        }
        .font(.system(size: 15, weight: .semibold))
        .foregroundStyle(item.id == selection ? selectedText : normalText)
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }
}
