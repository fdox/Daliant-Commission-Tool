import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: [SortDescriptor(\Org.createdAt, order: .forward)]) private var orgs: [Org]
    @AppStorage("signedInUserID") private var signedInUserID: String = ""

    var body: some View {
        NavigationStack {
            if signedInUserID.isEmpty {
                SignInView { userId, _ in
                    signedInUserID = userId
                }
            } else if orgs.isEmpty {
                OrgOnboardingView()
            } else {
                ProjectsHomeView()
            }
        }
    }
}

#Preview("App Flow (seeded)") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Org.self, Item.self, configurations: config)
    let ctx = ModelContext(container)
    // Seed an org and a couple of projects for preview
    ctx.insert(Org(name: "Daliant Lighting"))
    ctx.insert(Item(title: "Smith Residence"))
    ctx.insert(Item(title: "Beach House"))
    return ContentView()
        .modelContainer(container)
}
