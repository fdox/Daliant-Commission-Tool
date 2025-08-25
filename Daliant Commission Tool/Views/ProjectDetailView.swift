//
//  ProjectDetailView.swift
//  Daliant Commission Tool
//
//  Created by Fred Dox on 8/24/25.
//

import SwiftUI
import SwiftData

// MARK: - Project Detail (tabbed skeleton)

struct ProjectDetailView: View {
    @Bindable var project: Item

    // Required when using @Bindable in a custom init.
    init(project: Item) { self._project = Bindable(project) }

    var body: some View {
        TabView {
            // 1) Scan
            ScanTab()
                .tabItem { Label("Scan", systemImage: "dot.radiowaves.left.and.right") }

            // 2) Fixtures
            FixturesTab(project: project)
                .tabItem { Label("Fixtures", systemImage: "lightbulb") }

            // 3) Rooms
            RoomsTab(project: project)
                .tabItem { Label("Rooms", systemImage: "square.grid.2x2") }

            // 4) Export
            ExportTab()
                .tabItem { Label("Export", systemImage: "square.and.arrow.up") }

            // 5) Project Settings
            ProjectSettingsTab(project: project)
                .tabItem { Label("Settings", systemImage: "gearshape") }
        }
        .navigationTitle(project.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}




// --- Step 5c: Fixtures tab with + button & sheet ---
private struct FixturesTab: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var project: Item
    @State private var showingAdd = false

    // --- 5e: Filters state ---
    @State private var filterAddressText: String = ""   // e.g. "0-10", "12", "-20", "30-"
    @State private var filterGroupsMask: UInt16 = 0     // any-of groups

    // Computed filtered list
    private var filteredFixtures: [Fixture] {
        var list = project.fixtures

        // Address filter
        let (minAddr, maxAddr) = parseAddressRange(filterAddressText)
        if let min = minAddr { list = list.filter { $0.shortAddress >= min } }
        if let max = maxAddr { list = list.filter { $0.shortAddress <= max } }

        // Groups filter (match any selected)
        if filterGroupsMask != 0 {
            list = list.filter { ($0.groups & filterGroupsMask) != 0 }
        }

        // nice, stable ordering
        return list.sorted {
            if $0.shortAddress != $1.shortAddress { return $0.shortAddress < $1.shortAddress }
            return $0.label.localizedCaseInsensitiveCompare($1.label) == .orderedAscending
        }
    }

    var body: some View {
        List {
            if project.fixtures.isEmpty {
                ContentUnavailableView {
                    Label("No fixtures yet", systemImage: "lightbulb.slash")
                } description: {
                    Text("Add fixtures manually while we stub commissioning.")
                } actions: {
                    Button("Add Fixture") { showingAdd = true }
                        .buttonStyle(.borderedProminent)
                }
            } else {
                // --- 5e: Filters UI (always visible when list has items) ---
                FixtureFiltersView(
                    addressText: $filterAddressText,
                    groupsMask: $filterGroupsMask,
                    onClear: { filterAddressText = ""; filterGroupsMask = 0 }
                )

                // header
                HStack {
                    Text("Label").font(.caption).foregroundStyle(.secondary)
                    Spacer()
                    Text("Addr").font(.caption).foregroundStyle(.secondary).monospacedDigit()
                    Spacer()
                    Text("Groups").font(.caption).foregroundStyle(.secondary).monospaced()
                    Spacer()
                    Text("Room").font(.caption).foregroundStyle(.secondary)
                    Spacer()
                    Text("Last Seen").font(.caption).foregroundStyle(.secondary)
                }
                .listRowSeparator(.hidden)

                if filteredFixtures.isEmpty {
                    ContentUnavailableView {
                        Label("No results", systemImage: "line.3.horizontal.decrease.circle")
                    } description: {
                        Text("Try clearing or adjusting filters.")
                    } actions: {
                        Button("Clear Filters") { filterAddressText = ""; filterGroupsMask = 0 }
                    }
                } else {
                    ForEach(filteredFixtures, id: \.persistentModelID) { f in
                        FixtureRow(fixture: f)
                    }
                }
            }
        }
        .listStyle(.plain)
        .navigationTitle("Fixtures")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingAdd = true
                } label: {
                    Label("Add Fixture", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAdd) {
            AddFixtureSheet(project: project)
                .presentationDetents([.medium, .large])
                .environment(\.modelContext, modelContext)
        }
    }
}

// Row for one fixture (keep your existing copy if present)
private struct FixtureRow: View {
    let fixture: Fixture

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(fixture.label).lineLimit(1).layoutPriority(1)
            Spacer(minLength: 8)
            Text("\(fixture.shortAddress)").monospacedDigit()
            Spacer(minLength: 8)
            Text(groupsString(fixture.groups)).monospaced().foregroundStyle(.secondary)
            Spacer(minLength: 8)
            Text(fixture.room?.isEmpty == false ? fixture.room! : "—").foregroundStyle(.secondary)
            Spacer(minLength: 8)
            Text(lastSeenString(fixture.commissionedAt)).foregroundStyle(.secondary)
        }
        .contentShape(Rectangle())
        .padding(.vertical, 4)
    }
}

// --- 5e: Filters Section ---
private struct FixtureFiltersView: View {
    @Binding var addressText: String
    @Binding var groupsMask: UInt16
    var onClear: () -> Void

    var body: some View {
        Section {
            // Address range
            VStack(alignment: .leading, spacing: 6) {
                TextField("Address (e.g., 0-10, 12, -20, 30-)", text: $addressText)
                    .textInputAutocapitalization(.never)
                Text(addressHint(addressText))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            // Groups (match any)
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Groups (match any)")
                    if groupsMask != 0 {
                        Text("• \(selectedGroupList(groupsMask))")
                            .foregroundStyle(.secondary)
                    }
                }
                GroupsGrid(mask: $groupsMask)
            }

            // Clear
            HStack {
                Spacer()
                Button("Clear Filters", role: .cancel) { onClear() }
                    .disabled(addressText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && groupsMask == 0)
            }
        } header: {
            Text("Filters")
        }
    }
}

// Helpers (keep only one copy in this file)
private func groupsString(_ mask: UInt16) -> String {
    var out: [String] = []
    for i in 0..<16 {
        let bit: UInt16 = 1 << UInt16(i)
        if (mask & bit) != 0 { out.append("G\(i)") }
    }
    return out.isEmpty ? "—" : out.joined(separator: ",")
}

private func lastSeenString(_ date: Date?) -> String {
    guard let d = date else { return "—" }
    let fmt = DateFormatter()
    fmt.dateStyle = .medium
    fmt.timeStyle = .none
    return fmt.string(from: d)
}

// --- 5e Helpers ---
private func parseAddressRange(_ text: String) -> (Int?, Int?) {
    // Normalize weird hyphens/en-dashes and spaces
    var t = text.replacingOccurrences(of: "–", with: "-")
                .replacingOccurrences(of: "—", with: "-")
                .replacingOccurrences(of: "−", with: "-")
                .replacingOccurrences(of: " ", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)

    if t.isEmpty { return (nil, nil) }

    // Single number => exact match
    if let v = Int(t) {
        let c = clampAddress(v)
        return (c, c)
    }

    // Range variants: "a-b", "-b", "a-"
    let parts = t.split(separator: "-", omittingEmptySubsequences: false)
    let left  = parts.indices.contains(0) ? String(parts[0]) : ""
    let right = parts.indices.contains(1) ? String(parts[1]) : ""

    var minVal: Int? = left.isEmpty  ? nil : Int(left).map(clampAddress)
    var maxVal: Int? = right.isEmpty ? nil : Int(right).map(clampAddress)

    // If both present and swapped, fix order
    if let minV = minVal, let maxV = maxVal, minV > maxV {
        swap(&minVal, &maxVal)
    }
    return (minVal, maxVal)
}

private func clampAddress(_ v: Int) -> Int { max(0, min(63, v)) }

private func selectedGroupList(_ mask: UInt16) -> String {
    var items: [String] = []
    for i in 0..<16 {
        let bit: UInt16 = 1 << UInt16(i)
        if (mask & bit) != 0 { items.append("G\(i)") }
    }
    return items.joined(separator: ",")
}

private func addressHint(_ text: String) -> String {
    let (minA, maxA) = parseAddressRange(text)
    switch (minA, maxA) {
    case (nil, nil): return "Showing all addresses 0–63"
    case let (m?, n?): return "Showing \(m)–\(n)"
    case let (m?, nil): return "Showing \(m)–63"
    case let (nil, n?): return "Showing 0–\(n)"
    }
}

// --- Step 5c: Add Fixture sheet (Canvas‑friendly) ---
private struct AddFixtureSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var ctx
    @Bindable var project: Item

    @State private var label: String = ""
    @State private var address: Int = 0                // 0…63
    @State private var groupsMask: UInt16 = 0          // G0…G15 bitmask
    @State private var room: String = ""
    @State private var dtType: String = ""             // "", "DT6", "DT8", "D4i"

    private var canSave: Bool {
        !label.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Required") {
                    TextField("Label", text: $label)
                        .textInputAutocapitalization(.words)
                    Picker("Address", selection: $address) {
                        ForEach(0..<64, id: \.self) { Text("\($0)") }
                    }
                }

                Section("Groups") {
                    GroupsGrid(mask: $groupsMask)
                }

                Section("Optional") {
                    TextField("Room", text: $room)
                        .textInputAutocapitalization(.words)
                    Picker("DT Type", selection: $dtType) {
                        Text("—").tag("")
                        Text("DT6").tag("DT6")
                        Text("DT8").tag("DT8")
                        Text("D4i").tag("D4i")
                    }
                }
            }
            .navigationTitle("Add Fixture")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let trimmed = label.trimmingCharacters(in: .whitespacesAndNewlines)
                        let fixture = Fixture(
                            label: trimmed,
                            shortAddress: address,
                            groups: groupsMask,
                            room: room.nilIfEmpty,
                            serial: nil,
                            dtTypeRaw: dtType.nilIfEmpty,
                            commissionedAt: nil,
                            notes: nil
                            // no need to pass `project:` here
                        )

                        // Link + insert in one shot
                        project.fixtures.append(fixture)

                        // Persist and refresh UI
                        try? ctx.save()
                        dismiss()
                    }
                    .disabled(!canSave)
                }
            }
        }
    }
}

// Compact chip grid for G0…G15
private struct GroupsGrid: View {
    @Binding var mask: UInt16
    private let columns = [GridItem(.adaptive(minimum: 52, maximum: 72))]

    var body: some View {
        LazyVGrid(columns: columns, alignment: .leading, spacing: 8) {
            ForEach(0..<16, id: \.self) { i in
                let on = (mask & (1 << UInt16(i))) != 0
                Button {
                    let bit: UInt16 = 1 << UInt16(i)
                    if (mask & bit) != 0 { mask &= ~bit } else { mask |= bit }
                } label: {
                    Text("G\(i)")
                        .font(.callout)
                        .padding(.vertical, 6)
                        .padding(.horizontal, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(on ? Color.accentColor.opacity(0.15) : Color.clear)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(on ? Color.accentColor : Color.secondary.opacity(0.35))
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// tiny convenience for Optional fields
private extension String {
    var nilIfEmpty: String? {
        let t = trimmingCharacters(in: .whitespacesAndNewlines)
        return t.isEmpty ? nil : t
    }
}

// MARK: - Tabs (placeholders for now)

private struct ScanTab: View {
    var body: some View {
        VStack(spacing: 16) {
            Text("Commissioning")
                .font(.title3).bold()
            Text("Tap Start Scan to look for fixtures.")
                .foregroundStyle(.secondary)

            Button("Start Scan") {
                // BLE not wired yet (Step 7)
            }
            .buttonStyle(.borderedProminent)

            Spacer()

            ContentUnavailableView(
                "No devices found yet",
                systemImage: "lightbulb",
                description: Text("Run a scan to discover fixtures.")
            )
            .frame(maxWidth: .infinity, alignment: .top)
        }
        .padding()
    }
}


// --- Step 5d: Rooms tab (grouped by room) ---
private struct RoomsTab: View {
    @Bindable var project: Item

    var body: some View {
        List {
            if project.fixtures.isEmpty {
                ContentUnavailableView {
                    Label("Rooms view", systemImage: "square.grid.2x2")
                } description: {
                    Text("Add fixtures to see them grouped by room.")
                }
            } else {
                ForEach(roomGroups(for: project)) { group in
                    Section {
                        ForEach(group.fixtures, id: \.persistentModelID) { f in
                            FixtureRow(fixture: f)   // Reuse the existing row
                        }
                    } header: {
                        HStack {
                            Text(group.name)
                            Spacer()
                            Text("\(group.fixtures.count)")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .listStyle(.plain)
        .navigationTitle("Rooms")
    }
}

// Identifiable wrapper so ForEach is happy
private struct RoomGroup: Identifiable {
    var name: String
    var fixtures: [Fixture]
    var id: String { name }
}

// Helper to compute groups & sorting (kept private in this file)
private func roomGroups(for project: Item) -> [RoomGroup] {
    // Normalize room names; empty/nil => "Unassigned"
    let normalized = Dictionary(grouping: project.fixtures) { (f: Fixture) -> String in
        let t = (f.room ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        return t.isEmpty ? "Unassigned" : t
    }

    // Sort fixtures within a room: by address, then label
    func fixtureSort(_ a: Fixture, _ b: Fixture) -> Bool {
        if a.shortAddress != b.shortAddress { return a.shortAddress < b.shortAddress }
        return a.label.localizedCaseInsensitiveCompare(b.label) == .orderedAscending
    }

    // Sort room sections: alphabetical, "Unassigned" last
    let roomNames = normalized.keys.sorted { a, b in
        if a == "Unassigned" { return false }
        if b == "Unassigned" { return true }
        return a.localizedCaseInsensitiveCompare(b) == .orderedAscending
    }

    return roomNames.map { name in
        RoomGroup(name: name, fixtures: (normalized[name] ?? []).sorted(by: fixtureSort))
    }
}

private struct ExportTab: View {
    var body: some View {
        VStack(spacing: 16) {
            Button("Export PDF") { }
                .buttonStyle(.borderedProminent)
                .disabled(true)
            Text("Export is coming soon.")
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding()
    }
}

// MARK: - Project Settings (edit fields from the wizard)

private struct ProjectSettingsTab: View {
    @Environment(\.modelContext) private var context
    @Bindable var project: Item

    // Segmented control for control system
    @State private var csIndex: Int
    private let options = ["control4", "crestron", "lutron"]

    init(project: Item) {
        self._project = Bindable(project)
        self._csIndex = State(initialValue: Self.index(for: project.controlSystemRaw))
    }

    private static func index(for raw: String?) -> Int {
        switch raw?.lowercased() {
        case "crestron": return 1
        case "lutron":   return 2
        default:         return 0 // control4
        }
    }

    var body: some View {
        Form {
            Section("Basics") {
                TextField("Project name", text: $project.title)
                    .textInputAutocapitalization(.words)
            }

            Section("Contact") {
                TextField("First name", text: Binding(
                    get: { project.contactFirstName ?? "" },
                    set: { project.contactFirstName = $0.isEmpty ? nil : $0 }
                ))
                .textInputAutocapitalization(.words)

                TextField("Last name", text: Binding(
                    get: { project.contactLastName ?? "" },
                    set: { project.contactLastName = $0.isEmpty ? nil : $0 }
                ))
                .textInputAutocapitalization(.words)
            }

            Section("Site") {
                TextField("Site address", text: Binding(
                    get: { project.siteAddress ?? "" },
                    set: { project.siteAddress = $0.isEmpty ? nil : $0 }
                ))
                .textInputAutocapitalization(.words)
            }

            Section("Control system") {
                Picker("Control system", selection: $csIndex) {
                    Text("Control4").tag(0)
                    Text("Crestron").tag(1)
                    Text("Lutron").tag(2)
                }
                .pickerStyle(.segmented)
                .onChange(of: csIndex) { i in
                    project.controlSystemRaw = options[i]
                }
            }

            Section {
                Button("Save Changes") {
                    try? context.save()
                }
            }
        }
    }
}

#if DEBUG
import SwiftData

// Preview helper (single expression in #Preview)
private enum ProjectDetailPreviewFactory {
    @MainActor
    static func view() -> some View {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: Org.self, Item.self, configurations: config)
        let ctx = container.mainContext

        let item = Item(title: "Beach House")
        item.contactFirstName = "Dana"
        item.contactLastName  = "Lee"
        item.siteAddress      = "123 Ocean Ave"
        item.controlSystemRaw = "lutron"
        item.createdAt        = Date()

        ctx.insert(item)
        _ = try? ctx.save()

        return NavigationStack { ProjectDetailView(project: item) }
            .modelContainer(container)
    }
}

#Preview("Project Detail — Seeded") {
    ProjectDetailPreviewFactory.view()
}
#Preview("Project Detail — Fixtures") { ProjectDetail_FixturesPreview() }

@MainActor
private func ProjectDetail_FixturesPreview() -> some View {
    // In‑memory container with our models
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: Org.self, Item.self, Fixture.self,
        configurations: config
    )

    let org = Org(name: "Daliant")
    let project = Item(title: "Smith Residence")
    project.controlSystemRaw = "lutron"
    project.contactFirstName = "Alex"
    project.contactLastName = "Smith"
    project.siteAddress = "123 Palm Way"
    project.createdAt = .now

    // Seed a few fixtures
    let f1 = Fixture(label: "Kitchen Island", shortAddress: 1, groups: 0b0001, room: "Kitchen", dtTypeRaw: "DT8", commissionedAt: .now.addingTimeInterval(-86400), project: project)
    let f2 = Fixture(label: "Dining Chandelier", shortAddress: 6, groups: 0b1001, room: "Dining", dtTypeRaw: "DT6", commissionedAt: .now.addingTimeInterval(-3 * 86400), project: project)
    let f3 = Fixture(label: "Hall Sconce", shortAddress: 23, groups: 0, room: "Hall", dtTypeRaw: "D4i", commissionedAt: nil, project: project)

    let ctx = container.mainContext
    ctx.insert(org)
    ctx.insert(project)
    ctx.insert(f1); ctx.insert(f2); ctx.insert(f3)

    // Single expression return for the preview
    return ProjectDetailView(project: project)
        .modelContainer(container)
}
#endif
