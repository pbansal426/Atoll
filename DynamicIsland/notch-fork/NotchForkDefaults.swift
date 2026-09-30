import Defaults
import Foundation

extension Defaults.Keys {
    /// CPU/GPU/RAM/fan strip under the home view when the notch is hovered open.
    static let showHomeStatsStrip = Key<Bool>("notchForkShowHomeStatsStrip", default: true)
    /// Closed-notch fan activity at >= 50% of max RPM.
    static let enableFanLiveActivity = Key<Bool>("notchForkEnableFanLiveActivity", default: true)
    /// Closed-notch wings: one pinned stat on each side of the notch.
    static let pinnedMode = Key<Bool>("notchForkPinnedMode", default: false)
    static let pinnedLeft = Key<PinnedValue>("notchForkPinnedLeft", default: .cpu)
    static let pinnedRight = Key<PinnedValue>("notchForkPinnedRight", default: .ram)
}

/// Copies pre-rename dotted `notchFork.*` values into the dot-free keys.
/// Defaults observes keys by KVO path, so a dot never notifies.
enum NotchForkDefaultsMigration {
    static let renames: [(old: String, new: String)] = [
        ("notchFork.showHomeStatsStrip", "notchForkShowHomeStatsStrip"),
        ("notchFork.enableFanLiveActivity", "notchForkEnableFanLiveActivity"),
        ("notchFork.pinnedMode", "notchForkPinnedMode"),
        ("notchFork.pinnedLeft", "notchForkPinnedLeft"),
        ("notchFork.pinnedRight", "notchForkPinnedRight"),
    ]

    /// Copies each old value only when the new key has no stored value.
    /// Registered Defaults defaults do not count as stored. Leaves the old key in place.
    /// A second call is a no-op once the new keys exist in the persistent domain.
    static func migrate(_ defaults: UserDefaults, persistentDomainName: String) {
        let persisted = defaults.persistentDomain(forName: persistentDomainName) ?? [:]
        for rename in renames {
            guard persisted[rename.new] == nil else { continue }
            guard let existing = persisted[rename.old] else { continue }
            defaults.set(existing, forKey: rename.new)
        }
    }
}
