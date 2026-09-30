import Foundation

struct FanAlertPolicy: Equatable {
    var showFraction: Double = 0.50
    var hideFraction: Double = 0.45
    var hideDelay: TimeInterval = 10
}

/// Decides whether the fan live activity is showing. It appears as soon as the
/// fastest fan reaches `showFraction` of its maximum, and only leaves once it
/// has stayed below `hideFraction` for `hideDelay` -- so a fan idling near the
/// threshold does not flicker the notch.
struct FanAlertStateMachine {
    let policy: FanAlertPolicy
    private(set) var isAlerting = false
    private var belowHideSince: Date?

    init(policy: FanAlertPolicy = FanAlertPolicy()) {
        self.policy = policy
    }

    /// `fraction` is `nil` when the fans cannot be read; that hides at once
    /// rather than leaving a stale alert up.
    @discardableResult
    mutating func update(fraction: Double?, now: Date) -> Bool {
        guard let fraction else {
            isAlerting = false
            belowHideSince = nil
            return isAlerting
        }
        if fraction >= policy.showFraction {
            isAlerting = true
            belowHideSince = nil
        } else if isAlerting {
            if fraction < policy.hideFraction {
                let since = belowHideSince ?? now
                belowHideSince = since
                if now.timeIntervalSince(since) >= policy.hideDelay {
                    isAlerting = false
                    belowHideSince = nil
                }
            } else {
                belowHideSince = nil
            }
        }
        return isAlerting
    }
}
