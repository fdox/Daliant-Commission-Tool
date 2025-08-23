import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()
                Image(systemName: "lightbulb")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 96)
                    .foregroundStyle(.yellow)

                Text("Daliant Commission Tool")
                    .font(.title).bold()
                    .multilineTextAlignment(.center)

                Text("Commission Pod4 fixtures over Bluetooth.\nAssign DALI short addresses quickly—no site DALI loop.")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)

                NavigationLink {
                    ProjectsHomeView()
                } label: {
                    Text("Continue to Projects")
                }
                .buttonStyle(.borderedProminent)

                Spacer()
                Text("v0.1 • draft")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .padding()
        }
    }
}

struct ProjectsHomeView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Item.createdAt, order: .reverse) private var projects: [Item]
    @State private var newName: String = ""

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                TextField("New Project Name", text: $newName)
                    .textFieldStyle(.roundedBorder)
                    .submitLabel(.done)
                    .onSubmit(addProject)

                Button("Add") { addProject() }
                    .buttonStyle(.borderedProminent)
                    .disabled(newName.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding(.horizontal)

            List {
                ForEach(projects) { p in
                    NavigationLink {
                        ProjectDetailPlaceholder(project: p)
                    } label: {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(p.name).font(.headline)
                            Text(p.createdAt, style: .date)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .onDelete { idxSet in
                    for idx in idxSet { context.delete(projects[idx]) }
                }
            }
        }
        .navigationTitle("Projects")
        .toolbar { EditButton() }
    }

    private func addProject() {
        let name = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        context.insert(Item(name: name))
        newName = ""
    }
}

struct ProjectDetailPlaceholder: View {
    var project: Item
    var body: some View {
        VStack(spacing: 12) {
            Text("Project").font(.title2).bold()
            Text(project.name)
            Text("Address pool used: \(project.addressPoolUsed)")
                .foregroundStyle(.secondary)
        }
        .padding()
        .navigationTitle(project.name)
    }
}

// MARK: - Previews

#Preview("Landing – Light") {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
}

#Preview("Landing – Dark") {
    ContentView()
        .preferredColorScheme(.dark)
        .modelContainer(for: Item.self, inMemory: true)
}

/// Seed an in-memory container for Canvas previews (runs on the main actor).
@MainActor
private func previewSeededContainer() -> ModelContainer {
    let cfg = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Item.self, configurations: cfg)
    let ctx = container.mainContext
    ctx.insert(Item(name: "Smith Residence"))
    ctx.insert(Item(name: "Beach House"))
    return container
}

#Preview("Projects (Seeded)") {
    NavigationStack { ProjectsHomeView() }
        .modelContainer(previewSeededContainer())
}

#Preview("Landing – Seeded") {
    ContentView()
        .modelContainer(previewSeededContainer())
}
