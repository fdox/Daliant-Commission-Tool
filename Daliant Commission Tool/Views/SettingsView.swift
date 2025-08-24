import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @AppStorage("signedInUserID") private var signedInUserID: String = ""
    @Query(sort: [SortDescriptor(\Org.createdAt, order: .forward)]) private var orgs: [Org]

    @State private var name: String = ""
    @State private var showDeleteAlert = false

    var body: some View {
        Form {
            if let org = orgs.first {
                Section("Organization") {
                    TextField("Organization name", text: $name)
                        .onAppear { name = org.name }
                    Button("Save Name") {
                        let newName = name.trimmingCharacters(in: .whitespaces)
                        if !newName.isEmpty, newName != org.name { org.name = newName }
                    }
                }
                Section {
                    Button(role: .destructive) { showDeleteAlert = true } label: {
                        Text("Delete Organization")
                    }
                }
            } else {
                Section {
                    Text("No organization found. Create one to continue.")
                        .foregroundStyle(.secondary)
                }
            }

            Section("Account") {
                Button("Sign Out", role: .destructive) {
                    signedInUserID = ""
                    dismiss()
                }
            }
        }
        .navigationTitle("Settings")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) { Button("Done") { dismiss() } }
        }
        .alert("Delete Organization?", isPresented: $showDeleteAlert) {
            Button("Delete", role: .destructive) {
                if let org = orgs.first { context.delete(org); try? context.save() }
                dismiss()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This removes your org from this device’s data store.")
        }
    }
}

#Preview("Seeded Settings") {
    NavigationStack {
        SettingsView()
    }
    .modelContainer(for: [Org.self], inMemory: true) { container in
        let ctx = ModelContext(container)
        ctx.insert(Org(name: "Daliant Lighting"))
    }
}
