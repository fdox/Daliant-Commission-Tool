import Foundation
import SwiftData

/// Item == Project (keeping the original type name for now)
@Model
final class Item {
    var name: String
    var createdAt: Date
    /// Bit i set => DALI short address i (0–63) is used in this Project
    var addressPoolUsed: UInt64

    // Project details
    var contactFirstName: String?
    var contactLastName: String?
    var siteAddress: String?
    var controlSystemRaw: String  // persisted raw value

    init(name: String,
         contactFirstName: String? = nil,
         contactLastName: String? = nil,
         siteAddress: String? = nil,
         controlSystem: ControlSystem = .control4)
    {
        self.name = name
        self.createdAt = .now
        self.addressPoolUsed = 0
        self.contactFirstName = contactFirstName
        self.contactLastName = contactLastName
        self.siteAddress = siteAddress
        self.controlSystemRaw = controlSystem.rawValue
    }

    var controlSystem: ControlSystem {
        get { ControlSystem(rawValue: controlSystemRaw) ?? .control4 }
        set { controlSystemRaw = newValue.rawValue }
    }

    var contactFullName: String {
        let f = (contactFirstName ?? "").trimmingCharacters(in: .whitespaces)
        let l = (contactLastName ?? "").trimmingCharacters(in: .whitespaces)
        return [f, l].filter { !$0.isEmpty }.joined(separator: " ")
    }
}

/// Supported control systems
enum ControlSystem: String, CaseIterable, Codable, Identifiable {
    case control4 = "Control4"
    case crestron = "Crestron"
    case lutron   = "Lutron"
    var id: String { rawValue }
}

/// Organization (e.g., "Dox Electronics")
@Model
final class Org {
    @Attribute(.unique) var slug: String        // "dox-electronics"
    var name: String
    var joinCode: String                        // short internal code
    var createdAt: Date

    init(name: String, slug: String, joinCode: String) {
        self.name = name
        self.slug = slug
        self.joinCode = joinCode
        self.createdAt = .now
    }
}
