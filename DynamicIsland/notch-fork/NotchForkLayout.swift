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

    /// `CGRect.contains` excludes the max edges. Menu-bar clicks land on
    /// `y == screen.frame.maxY`, so pill clicks and the closed hover rect must
    /// include that edge. Max X stays excluded.
    static func containsIncludingMaxY(_ rect: CGRect, point: CGPoint) -> Bool {
        point.x >= rect.minX && point.x < rect.maxX
            && point.y >= rect.minY && point.y <= rect.maxY
    }

    static func hoverClickTargetsPill(at location: CGPoint, pillRect: CGRect) -> Bool {
        containsIncludingMaxY(pillRect, point: location)
    }

    static func shouldIgnoreClosedHoverExit(at location: CGPoint, pillRect: CGRect) -> Bool {
        containsIncludingMaxY(closedHoverRect(pillRect: pillRect), point: location)
    }

    static func retainsClosedHover(at location: CGPoint, exitRect: CGRect, pillRect: CGRect) -> Bool {
        exitRect.contains(location) || shouldIgnoreClosedHoverExit(at: location, pillRect: pillRect)
    }

    static func updatedClosedPillSize(current: CGSize, measured: CGSize, isClosed: Bool) -> CGSize {
        isClosed ? measured : current
    }

    static func isInsideTopBand(mouseY: CGFloat, screenMaxY: CGFloat, bandHeight: CGFloat) -> Bool {
        mouseY <= screenMaxY && mouseY >= screenMaxY - bandHeight
    }

    enum SideHoverDecision: Equatable {
        case enter
        case exit
        case none
    }

    /// Closed notch only. Enter from the widened hover rect. Once hovering,
    /// leave only when the cursor is outside that rect and the closed hit area.
    static func sideHoverDecision(
        pillRect: CGRect,
        cursor: CGPoint,
        isHovering: Bool,
        isClosed: Bool,
        inClosedHitArea: Bool
    ) -> SideHoverDecision {
        guard isClosed else { return .none }
        let inHoverRect = shouldIgnoreClosedHoverExit(at: cursor, pillRect: pillRect)
        if isHovering {
            return (inHoverRect || inClosedHitArea) ? .none : .exit
        }
        return inHoverRect ? .enter : .none
    }
}
