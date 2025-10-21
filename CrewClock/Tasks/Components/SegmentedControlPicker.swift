//
//  SegmentedControlPicker.swift
//  CrewClock
//
//  Created by Edgars Yarmolatiy on 10/21/25.
//

import SwiftUI

// MARK: - A locally-tinted UISegmentedControl wrapped for SwiftUI
struct SegmentedControlPicker<T: Hashable & Identifiable & CustomStringConvertible>: UIViewRepresentable {
    @Binding var selection: T
    let items: [T]
    var selectedTint: UIColor
    var selectedText: UIColor
    var normalText: UIColor

    func makeUIView(context: Context) -> UISegmentedControl {
        let control = UISegmentedControl(items: items.map { $0.description })
        control.addTarget(context.coordinator, action: #selector(Coordinator.changed(_:)), for: .valueChanged)
        control.selectedSegmentTintColor = selectedTint
        let normalAttrs: [NSAttributedString.Key: Any] = [.foregroundColor: normalText]
        let selectedAttrs: [NSAttributedString.Key: Any] = [.foregroundColor: selectedText]
        control.setTitleTextAttributes(normalAttrs, for: .normal)
        control.setTitleTextAttributes(selectedAttrs, for: .selected)
        if let idx = items.firstIndex(of: selection) { control.selectedSegmentIndex = idx }
        return control
    }

    func updateUIView(_ uiView: UISegmentedControl, context: Context) {
        // Rebuild segments if count or titles changed
        if uiView.numberOfSegments != items.count {
            uiView.removeAllSegments()
            for (i, item) in items.enumerated() {
                uiView.insertSegment(withTitle: item.description, at: i, animated: false)
            }
        } else {
            for (i, item) in items.enumerated() {
                if uiView.titleForSegment(at: i) != item.description {
                    uiView.setTitle(item.description, forSegmentAt: i)
                }
            }
        }
        // Colors (kept local to this instance)
        uiView.selectedSegmentTintColor = selectedTint
        let normalAttrs: [NSAttributedString.Key: Any] = [.foregroundColor: normalText]
        let selectedAttrs: [NSAttributedString.Key: Any] = [.foregroundColor: selectedText]
        uiView.setTitleTextAttributes(normalAttrs, for: .normal)
        uiView.setTitleTextAttributes(selectedAttrs, for: .selected)

        // Selection
        if let idx = items.firstIndex(of: selection), uiView.selectedSegmentIndex != idx {
            uiView.selectedSegmentIndex = idx
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }
    class Coordinator: NSObject {
        let parent: SegmentedControlPicker
        init(_ parent: SegmentedControlPicker) { self.parent = parent }
        @objc func changed(_ sender: UISegmentedControl) {
            let idx = max(0, sender.selectedSegmentIndex)
            guard idx < parent.items.count else { return }
            parent.selection = parent.items[idx]
        }
    }
}
