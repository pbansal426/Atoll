import Defaults

extension Defaults.Keys {
    /// CPU/GPU/RAM/fan strip under the home view when the notch is hovered open.
    static let showHomeStatsStrip = Key<Bool>("notchFork.showHomeStatsStrip", default: true)
    /// Closed-notch fan activity at >= 50% of max RPM.
    static let enableFanLiveActivity = Key<Bool>("notchFork.enableFanLiveActivity", default: true)
}
