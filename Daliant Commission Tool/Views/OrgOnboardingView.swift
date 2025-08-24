import SwiftUI
import SwiftData

struct OrgOnboardingView: View {
    @Environment(\.modelContext) private var context
    @State private var name: String = ""

    var body: some View {
        Form {
            Section("Organization") {
                TextField("Organization name", text: $name)
            }
            Section {
                Button("Create Organization") {
                    guard !name.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                    context.insert(Org(name: name.trimmingCharacters(in: .whitespaces)))
                }
                .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .navigationTitle("Welcome")
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Org.self, configurations: config)
    return NavigationStack { OrgOnboardingView() }
        .modelContainer(container)
}
