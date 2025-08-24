//  ProjectsHomeView.swift
//  Daliant Commission Tool
//
//  Phase 3 – Step 1 update:
//  - Uses Item.name (not Item.title)
//  - Adds simple search
//  - Gear button opens SettingsView
//  - Canvas-friendly preview with in-memory SwiftData

import SwiftUI
import SwiftData

struct ProjectsHomeView: View {
    @Environment(\.modelContext) private var context
    @State private var showingSettings = false
    @State private var query: String = ""

    @Query private var projects: [Item]

    var body: some View {
        NavigationStack {
            Group {
                let filtered = filteredProjects()
                if filtered.isEmpty {
                    ContentUnavailableView("No Projects",
                                           systemImage: "folder",
                                           description: Text("Tap + (coming soon) or use the wizard to create your first project."))
                        .padding()
                } else {
                    List {
                        ForEach(filtered) { p in
                            NavigationLink {
                                // Replace this stub with your Project Detail screen when ready.
                                Text("Project Detail (coming soon)")
                                    .navigationTitle(projectName(p))
                            } label: {
                                ProjectCardRow(name: projectName(p),
                                               controlSystemTag: projectControlSystemTag(p),
                                               contact: projectContact(p))
                            }
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                            .background(Color.clear)
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Projects")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                    .accessibilityLabel("Settings")
                }
            }
            .sheet(isPresented: $showingSettings) {
                NavigationStack { SettingsView() }
            }
        }
        .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always))
    }

    private func filteredProjects() -> [Item] {
        let base = projects.sorted {
            projectName($0).localizedStandardCompare(projectName($1)) == .orderedAscending
        }
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return base }
        return base.filter { projectName($0).localizedCaseInsensitiveContains(query) }
    }

    // MARK: - Safe accessors (avoid compile breaks if model fields change)

    private func projectName(_ item: Item) -> String {
        if let n = Mirror(reflecting: item).children.first(where: { $0.label == "name" })?.value as? String, !n.isEmpty {
            return n
        }
        if let t = Mirror(reflecting: item).children.first(where: { $0.label == "title" })?.value as? String, !t.isEmpty {
            return t
        }
        return "Untitled"
    }

    private func projectControlSystemTag(_ item: Item) -> String? {
        if let raw = Mirror(reflecting: item).children.first(where: { $0.label == "controlSystemRaw" })?.value as? String, !raw.isEmpty {
            return prettyControlSystem(raw)
        }
        if let enumVal = Mirror(reflecting: item).children.first(where: { $0.label == "controlSystem" })?.value {
            let s = String(describing: enumVal)
            return prettyControlSystem(s)
        }
        return nil
    }

    private func projectContact(_ item: Item) -> String? {
        let mirror = Mirror(reflecting: item)
        let first = mirror.children.first(where: { $0.label == "contactFirstName" })?.value as? String
        let last  = mirror.children.first(where: { $0.label == "contactLastName" })?.value as? String
        let full = [first, last].compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }.joined(separator: " ")
        return full.isEmpty ? nil : full
    }

    private func prettyControlSystem(_ raw: String) -> String {
        let s = raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        switch s {
        case "control4", ".control4": return "Control4"
        case "crestron", ".crestron": return "Crestron"
        case "lutron", ".lutron":     return "Lutron"
        default: return raw.isEmpty ? "—" : raw
        }
    }
}

private struct ProjectCardRow: View {
    let name: String
    let controlSystemTag: String?
    let contact: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(name)
                .font(.headline)
                .lineLimit(1)
            HStack(spacing: 8) {
                if let tag = controlSystemTag {
                    Text(tag)
                        .font(.caption)
                        .padding(.horizontal, 8).padding(.vertical, 4)
                        .background(.thinMaterial, in: Capsule())
                        .accessibilityLabel("Control system \(tag)")
                }
                if let contact {
                    Text(contact)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(uiColor: .secondarySystemBackground))
        )
    }
}

#Preview("Projects – Seeded") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Org.self, Item.self, configurations: config)
    let context = container.mainContext

    do {
        let org = Org(name: "Dox Electronics", joinCode: "DOX123")
        context.insert(org)

        let p1 = Item(name: "Smith Residence")
        let p2 = Item(name: "Beach House")
        context.insert(p1)
        context.insert(p2)
        try context.save()
    } catch {
        assertionFailure("Preview seeding failed: \(error)")
    }

    return ProjectsHomeView()
        .modelContainer(container)
}
