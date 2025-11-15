//
//  AppearanceView.swift
//  CrewClock
//
//  Created by Edgars Yarmolatiy on 11/15/25.
//

import SwiftUI

/// Simple view for changing app appearance settings like accent color and corner radius.
struct AppearanceView: View {

    // MARK: - AppStorage-backed properties
    @AppStorage(K.UI.cornerRadiusKey) private var cornerRadius: Double = Double(K.UI.defaultCornerRadius)
    @AppStorage(K.Colors.accentIndexKey) private var accentIndex: Int = 0
    @AppStorage(K.UI.paddingKey) private var padding: Double = Double(K.UI.defaultPadding)

    private let previewHeight: CGFloat = 80

    var body: some View {
        GlassList {
            accentRow
            cornerRadiusRow
            paddingRow
        }
        .navigationTitle("Appearance")
    }

    private var accentRow: some View {
        accentColorSection
    }

    private var cornerRadiusRow: some View {
        cornerRadiusSection
    }

    private var paddingRow: some View {
        paddingSection
    }

    /// Section for selecting the global accent color.
    private var accentColorSection: some View {
        Section("Accent color") {
            accentColorScrollContainer
        }
        .listRowBackground(Color.clear)
        .listRowInsets(EdgeInsets())
        .cornerRadius(.infinity)
    }

    /// Wraps the scroll view in a ScrollViewReader to allow centering on the selected color.
    private var accentColorScrollContainer: some View {
        ScrollViewReader { proxy in
            accentColorScroll
                .onAppear {
                    proxy.scrollTo(accentIndex, anchor: .center)
                }
        }
    }

    /// Horizontal scroll of selectable accent color circles.
    private var accentColorScroll: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(K.Colors.teamColors.indices, id: \.self) { index in
                    accentColorCircle(for: index)
                        .id(index)
                }
            }
            .padding(.vertical, 4)
        }
    }

    /// Single color circle item with selection ring and tap handler.
    private func accentColorCircle(for index: Int) -> some View {
        let color = K.Colors.teamColors[index]

        return Circle()
            .fill(color)
            .frame(width: 32, height: 32)
            .overlay(
                Circle()
                    .strokeBorder(
                        Color.primary.opacity(index == accentIndex ? 0.8 : 0.2),
                        lineWidth: index == accentIndex ? 3 : 1
                    )
            )
            .padding(4)
            .onTapGesture {
                accentIndex = index
                Toast.shared.present(
                    title: "Color changed",
                    symbol: "paintpalette",
                    isUserInteractionEnabled: true,
                    timing: .medium
                )
            }
            .accessibilityLabel(Text(K.Colors.colorName(color)))
    }

    /// Section for previewing and adjusting the global corner radius.
    private var cornerRadiusSection: some View {
        Section {
            cornerRadiusPreview
            cornerRadiusSlider
        } header: {
            Text("Corner radius")
        } footer: {
            Text("24 is recommended corner radius")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    /// Rounded rectangle preview that reflects the current corner radius.
    private var cornerRadiusPreview: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(Color.secondary.opacity(0.15))
            .frame(height: previewHeight)
            .overlay(
                Text("Preview: \(Int(cornerRadius))")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            )
            .padding(.vertical, 8)
    }

    /// Slider that controls the global corner radius.
    private var cornerRadiusSlider: some View {
        Slider(
            value: $cornerRadius,
            in: 8...40,
            step: 4
        ) {
            Text("Corner radius")
        } minimumValueLabel: {
            Text("8")
        } maximumValueLabel: {
            Text("40")
        } onEditingChanged: { isEditing in
            if !isEditing {
                Toast.shared.present(
                    title: "Corner radius changed",
                    symbol: "checkmark.square",
                    isUserInteractionEnabled: true,
                    timing: .medium
                )
            }
        }
    }

    /// Section for adjusting default padding used in cards/rows.
    private var paddingSection: some View {
        Section {
            paddingPreview
            paddingSlider
        } header: {
            Text("Card padding")
        } footer: {
            Text("15 is recommended padding")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    /// Preview showing how the padding affects a rounded rectangle card.
    private var paddingPreview: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [4]))
            .frame(height: previewHeight / 2)
            .padding(EdgeInsets(top: padding, leading: padding, bottom: padding, trailing: padding))
            .overlay(
                Text("Padding: \(Int(padding))")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            )
    }

    /// Slider that controls the default card padding.
    private var paddingSlider: some View {
        Slider(
            value: $padding,
            in: 5...30,
            step: 2.5
        ) {
            Text("Padding")
        } minimumValueLabel: {
            Text("5")
        } maximumValueLabel: {
            Text("30")
        } onEditingChanged: { isEditing in
            if !isEditing {
                Toast.shared.present(
                    title: "Padding changed",
                    symbol: "arrow.left.and.right",
                    isUserInteractionEnabled: true,
                    timing: .medium
                )
            }
        }
    }
}
