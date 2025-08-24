import Foundation
import SwiftData

/// Keep using `Item` as the Project model for now (to avoid Xcode project file edits)
@Model
final class Item {
    @Attribute(.unique) var id: UUID
    var title: String
    var createdAt: Date

    init(title: String, createdAt: Date = .now) {
        self.id = UUID()
        self.title = title
        self.createdAt = createdAt
    }
}
