import Foundation
import SwiftData

@Model
final class Item { // We'll keep the type name 'Item' for now; it's our Project
    var name: String
    var createdAt: Date
    var addressPoolUsed: UInt64  // bit i set => DALI address i used

    init(name: String) {
        self.name = name
        self.createdAt = .now
        self.addressPoolUsed = 0
    }
}
