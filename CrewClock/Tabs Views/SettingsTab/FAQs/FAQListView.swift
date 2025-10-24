//
//  FAQListView.swift
//  CrewClock
//
//  Created by Edgars Yarmolatiy on 10/23/25.
//


import SwiftUI

struct FAQListView: View {
    @StateObject private var vm = FAQViewModel()
    @State private var expanded: Set<String> = []
    @State private var showTagsFilter: Bool = true
    
    private var isIOS26: Bool {
        if #available(iOS 26.0, *) {
            return false
        }else {
            return false
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Tags
                if showTagsFilter {
                    tagsScroll
                }

                if vm.isLoading {
                    ProgressView("Loading…").padding()
                } else if let err = vm.errorMessage {
                    Text(err).foregroundColor(.red).padding()
                }

                if #available(iOS 26.0, *) {
                    faqList
                        .searchToolbarBehavior(.automatic)
                } else {
                    faqList
                }
            }
            .navigationTitle("Help & FAQs")
            .task { await vm.loadOnce() }
        }
    }
    
    // Tags ScrollView
    private var tagsScroll: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                TagChip(title: "All", isSelected: vm.selectedTag == nil) { vm.selectedTag = nil }
                ForEach(vm.allTags, id: \.self) { tag in
                    TagChip(title: tag,
                            isSelected: vm.selectedTag?.lowercased() == tag.lowercased()) {
                        vm.selectedTag = tag
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 6)
        }
    }
    
    //list of all FAQs
    private var faqList: some View {
        GlassList {
            ForEach(vm.filtered) { faqItem in
               faqRow(faqItem)
            }
        }
        .listStyle(.insetGrouped)
        .searchable(text: $vm.searchText, prompt: "Search FAQs")
        .toolbar { toolbar }
        .refreshable { await vm.loadOnce() }
    }
    
    // Toolbar
    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        if #available(iOS 26, *) {
            DefaultToolbarItem(kind: .search, placement: .bottomBar)
        }
        if #available(iOS 26.0, *) {
            ToolbarSpacer(.flexible)
        }
        ToolbarItem(placement: .topBarTrailing) {
            Button("Filter", systemImage: "line.3.horizontal.decrease") { filterPressed() }
                .tint(showTagsFilter ? K.Colors.accent : .primary)
        }
    }

    
    //MARK: - ViewBuilders
    
    @ViewBuilder
    private func faqRow(_ faqItem: FAQ) -> some View {
        let rowID = faqItem.id ?? UUID().uuidString
        DisclosureGroup(
            isExpanded: Binding(
                get: { expanded.contains(rowID) },
                set: { expandedUpdate($0, id: rowID) }
            )
        ) {
            Text(faqItem.answer)
                .font(.body)
                .foregroundStyle(.primary)
                .padding(.top, 4)
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                Text(faqItem.question).font(.headline)
                if !faqItem.tags.isEmpty {
                    Text(faqItem.tags.joined(separator: " • "))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .listRowSeparator(.visible)
    }
    
    //MARK: - Functions

    private func filterPressed() {
        showTagsFilter.toggle()
        vm.selectedTag = nil
    }
    
    private func expandedUpdate(_ expand: Bool, id: String) {
        if expand { expanded.insert(id) } else { _ = expanded.remove(id) }
    }
}

private struct TagChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.callout)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(isSelected ? Color.accentColor.opacity(0.15) : Color(.secondarySystemBackground))
                .foregroundStyle(isSelected ? Color.accentColor : .primary)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}
