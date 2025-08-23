//
//  Daliant_Commission_ToolApp.swift
//  Daliant Commission Tool
//
//  Created by Fred Dox on 8/23/25.
//

import SwiftUI
import SwiftData

@main
struct Daliant_Commission_ToolApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
