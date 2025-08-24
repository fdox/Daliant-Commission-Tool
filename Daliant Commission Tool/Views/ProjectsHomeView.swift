import SwiftUI
import SwiftData

struct ProjectsHomeView: View {
    @Environment(\.modelContext) private var context
    @Query(of: Item.self, sort: .createdAt) private var projects: [Item]
    @State private var newTitle: String = ""

    var body: some View {
        List {
            Section {
                HStack {
                    TextField("New project name", text: $newTitle)
                    Button("Add") {
                        let t = newTitle.trimmingCharacters(in: .whitespaces)
                        guard !t.isEmpty else { return }
                        context.insert(Item(title: t))
                        newTitle = ""
                    }
                }
            }
            Section {
                ForEach(projects) { p in
                    NavigationLink(value: p.id) {
                        VStack(alignment: .leading) {
                            Text(p.title)
                            Text(p.createdAt, style: .date)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .onDelete { idx in
                    for i in idx { context.delete(projects[i]) }
                }
            }
        }
        .navigationTitle("Projects")
        .toolbar { ToolbarItem(placement: .topBarTrailing) { Image(systemName: "gearshape") } }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Item.self, configurations: config)
    let ctx = ModelContext(container)
    ctx.insert(Item(title: "Sample A"))
    ctx.insert(Item(title: "Sample B"))
    return NavigationStack { ProjectsHomeView() }
        .modelContainer(container)
}
