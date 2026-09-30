import Defaults

extension Defaults.Keys {
    /// CPU/GPU/RAM/fan strip under the home view when the notch is hovered open.
    static let showHomeStatsStrip = Key<Bool>("notchFork.showHomeStatsStrip", default: true)
    /// Closed-notch fan activity at >= 50% of max RPM.
    static let enableFanLiveActivity = Key<Bool>("notchFork.enableFanLiveActivity", default: true)
    /// Closed-notch wings: one pinned stat on each side of the notch.
    static let pinnedMode = Key<Bool>("notchFork.pinnedMode", default: false)
    static let pinnedLeft = Key<PinnedValue>("notchFork.pinnedLeft", default: .cpu)
    static let pinnedRight = Key<PinnedValue>("notchFork.pinnedRight", default: .ram)
}
