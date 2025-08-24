import SwiftUI
import SwiftData

@main
struct Daliant_Commission_ToolApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }


// MARK: - SwiftData Container
let sharedModelContainer: ModelContainer = {
    let schema = Schema([
        Org.self,
        Item.self
    ])
    let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
    return try! ModelContainer(for: schema, configurations: [config])
}()
