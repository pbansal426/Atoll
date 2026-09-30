import CoreGraphics

enum NotchForkLayout {
    /// Extra hover reach on each side of the closed notch/pill, so approaching
    /// from the left or right opens it (Atoll's zone is the bare visible shape).
    static let sideHoverMargin: CGFloat = 16

    static func closedHoverWidth(contentWidth: CGFloat) -> CGFloat {
        contentWidth + sideHoverMargin * 2
    }

    /// The pill's screen rect widened by `sideHoverMargin` on each side; same
    /// vertical extent. Hover-only: checked against the mouse location by an
    /// event monitor, never used as a window/hit-test area, so clicks in the
    /// margin still reach the menu-bar items underneath.
    static func closedHoverRect(pillRect: CGRect) -> CGRect {
        pillRect.insetBy(dx: -sideHoverMargin, dy: 0)
    }
}
