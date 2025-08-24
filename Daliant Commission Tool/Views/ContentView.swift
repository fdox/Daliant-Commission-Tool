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





#Preview("Seeded App Flow") {
    ContentView()
        .modelContainer(
            PreviewSeed.container([Org.self, Item.self]) { ctx in
                ctx.insert(Org(name: "Daliant Lighting"))
                ctx.insert(Item(title: "Smith Residence"))
                ctx.insert(Item(title: "Beach House"))
            }
        )

