//  SettingsView.swift
//  Daliant Commission Tool
//
//  Phase 3 – Step 1 update:
//  - Shows current Org name + join code
//  - "Join different org" by code (local behavior)
//  - "Sign out" deletes all Org records
//  - Canvas #Preview with in-memory SwiftData

import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @Query private var orgs: [Org]

    @State private var newJoinCode: String = ""
    @State private var errorMessage: String?

    var currentOrg: Org? { orgs.first }

    var body: some View {
        Form {
            Section("Organization") {
                HStack {
                    Text("Name").foregroundStyle(.secondary)
                    Spacer()
                    Text(currentOrgName())
                        .fontWeight(.semibold)
                }
                HStack {
                    Text("Join code").foregroundStyle(.secondary)
                    Spacer()
                    Text(currentOrgJoinCode())
                        .font(.body.monospaced())
                        .textSelection(.enabled)
                        .lineLimit(1)
                }
            }

            Section("Join different org") {
                TextField("Enter join code", text: $newJoinCode)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
                Button("Join") {
                    joinDifferentOrg()
                }
                .disabled(newJoinCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }

            Section {
                Button(role: .destructive) {
                    signOut()
                } label: {
                    Text("Sign out")
                }
            }
        }
        .navigationTitle("Settings")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Done") { dismiss() }
            }
        }
        .alert("Error", isPresented: .constant(errorMessage != nil), actions: {
            Button("OK", role: .cancel) { errorMessage = nil }
        }, message: {
            Text(errorMessage ?? "")
        })
    }

    // MARK: - Helpers

    private func currentOrgName() -> String {
        guard let org = currentOrg else { return "—" }
        if let n = Mirror(reflecting: org).children.first(where: { $0.label == "name" })?.value as? String, !n.isEmpty {
            return n
        }
        return "—"
    }

    private func currentOrgJoinCode() -> String {
        guard let org = currentOrg else { return "—" }
        if let c = Mirror(reflecting: org).children.first(where: { $0.label == "joinCode" })?.value as? String, !c.isEmpty {
            return c
        }
        return "—"
    }

    private func joinDifferentOrg() {
        let code = newJoinCode.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !code.isEmpty else { return }

        do {
            let fetch = FetchDescriptor<Org>()
            let all = try context.fetch(fetch)
            if let found = all.first(where: {
                (Mirror(reflecting: $0).children.first(where: { $0.label == "joinCode" })?.value as? String)?
                    .caseInsensitiveCompare(code) == .orderedSame
            }) {
                for o in all where o != found { context.delete(o) }
                try context.save()
                newJoinCode = ""
                return
            }

            for o in all { context.delete(o) }
            let newOrg = Org(name: "Org (\(code))", joinCode: code)
            context.insert(newOrg)
            try context.save()
            newJoinCode = ""
        } catch {
            errorMessage = "Could not switch org: \(error.localizedDescription)"
        }
    }

    private func signOut() {
        do {
            let fetch = FetchDescriptor<Org>()
            for o in try context.fetch(fetch) {
                context.delete(o)
            }
            try context.save()
            dismiss()
        } catch {
            errorMessage = "Sign out failed: \(error.localizedDescription)"
        }
    }
}

#Preview("Settings – Seeded") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Org.self, Item.self, configurations: config)
    let context = container.mainContext

    do {
        let org = Org(name: "Dox Electronics", joinCode: "DOX123")
        context.insert(org)
        try context.save()
    } catch {
        assertionFailure("Preview seed failed: \(error)")
    }

    return NavigationStack {
        SettingsView()
    }
    .modelContainer(container)
}
