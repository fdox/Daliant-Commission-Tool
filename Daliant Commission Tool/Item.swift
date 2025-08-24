import Foundation
import SwiftData

/// Item == Project (we keep the original type name to avoid project-file changes)
@Model
final class Item {
    var name: String
    var createdAt: Date
    /// Bit i set => DALI short address i (0–63) is used in this Project
    var addressPoolUsed: UInt64

    init(name: String) {
        self.name = name
        self.createdAt = .now
        self.addressPoolUsed = 0
    }
}

/// Organization the installer belongs to (e.g., "Dox Electronics")
@Model
final class Org {
    @Attribute(.unique) var slug: String      // "dox-electronics" (unique)
    var name: String                           // display name
    var joinCode: String                       // short code to share internally (local for now)
    var createdAt: Date

    init(name: String, slug: String, joinCode: String) {
        self.name = name
        self.slug = slug
        self.joinCode = joinCode
        self.createdAt = .now
    }
}
