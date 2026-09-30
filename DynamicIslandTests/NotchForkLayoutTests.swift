import XCTest
@testable import Atoll

final class NotchForkLayoutTests: XCTestCase {
    func testClosedHoverZoneAddsMarginOnBothSides() {
        XCTAssertEqual(NotchForkLayout.closedHoverWidth(contentWidth: 185), 217)
        XCTAssertEqual(NotchForkLayout.closedHoverWidth(contentWidth: 0), 32)
    }

    func testClosedHoverRectWidensSidesOnly() {
        let pill = CGRect(x: 100, y: 0, width: 185, height: 32)
        XCTAssertEqual(NotchForkLayout.closedHoverRect(pillRect: pill),
                       CGRect(x: 84, y: 0, width: 217, height: 32))
    }

    func testHoverClickTargetsThePillNotTheSideMargin() {
        let pill = CGRect(x: 100, y: 900, width: 185, height: 32)
        XCTAssertFalse(NotchForkLayout.hoverClickTargetsPill(at: CGPoint(x: 90, y: 916), pillRect: pill))
        XCTAssertTrue(NotchForkLayout.hoverClickTargetsPill(at: CGPoint(x: 150, y: 916), pillRect: pill))
    }

    func testHoverClickIncludesThePillsTopEdge() {
        let pill = CGRect(x: 100, y: 900, width: 185, height: 32)
        XCTAssertTrue(NotchForkLayout.hoverClickTargetsPill(at: CGPoint(x: 150, y: pill.maxY), pillRect: pill))
        XCTAssertFalse(NotchForkLayout.hoverClickTargetsPill(at: CGPoint(x: 150, y: pill.maxY + 1), pillRect: pill))
    }

    func testClosedHoverIncludesTopEdgeAndExactSideMargins() {
        let pill = CGRect(x: 100, y: 900, width: 185, height: 32)
        XCTAssertTrue(NotchForkLayout.shouldIgnoreClosedHoverExit(
            at: CGPoint(x: pill.minX - 16, y: pill.midY), pillRect: pill))
        XCTAssertFalse(NotchForkLayout.shouldIgnoreClosedHoverExit(
            at: CGPoint(x: pill.maxX + 16, y: pill.midY), pillRect: pill))
        XCTAssertTrue(NotchForkLayout.shouldIgnoreClosedHoverExit(
            at: CGPoint(x: pill.midX, y: pill.maxY), pillRect: pill))
        XCTAssertTrue(NotchForkLayout.shouldIgnoreClosedHoverExit(
            at: CGPoint(x: pill.minX - 16, y: pill.maxY), pillRect: pill))
    }

    func testClosedHoverExitKeepsPointsInsideTheEntryRect() {
        let pill = CGRect(x: 100, y: 900, width: 185, height: 40)
        let shortExit = CGRect(x: 84, y: 920, width: 217, height: 20)
        let point = CGPoint(x: 150, y: 910)
        XCTAssertFalse(shortExit.contains(point))
        XCTAssertTrue(NotchForkLayout.retainsClosedHover(at: point, exitRect: shortExit, pillRect: pill))
        XCTAssertFalse(NotchForkLayout.retainsClosedHover(at: CGPoint(x: 40, y: 910), exitRect: shortExit, pillRect: pill))
    }

    func testMarginBesideThePillStillCountsAsClosedHover() {
        let pill = CGRect(x: 100, y: 900, width: 185, height: 32)
        XCTAssertTrue(NotchForkLayout.shouldIgnoreClosedHoverExit(at: CGPoint(x: 90, y: 916), pillRect: pill))
        XCTAssertFalse(NotchForkLayout.shouldIgnoreClosedHoverExit(at: CGPoint(x: 150, y: 880), pillRect: pill))
    }

    func testClosedPillMeasurementIsKeptOnlyWhileClosed() {
        let current = CGSize(width: 120, height: 22)
        let measured = CGSize(width: 400, height: 80)
        XCTAssertEqual(
            NotchForkLayout.updatedClosedPillSize(current: current, measured: measured, isClosed: false),
            current
        )
        XCTAssertEqual(
            NotchForkLayout.updatedClosedPillSize(current: current, measured: measured, isClosed: true),
            measured
        )
    }

    func testTopBandRejectsCursorsBelowThePill() {
        XCTAssertTrue(NotchForkLayout.isInsideTopBand(mouseY: 1070, screenMaxY: 1080, bandHeight: 32))
        XCTAssertFalse(NotchForkLayout.isInsideTopBand(mouseY: 1000, screenMaxY: 1080, bandHeight: 32))
        XCTAssertTrue(NotchForkLayout.isInsideTopBand(mouseY: 1080, screenMaxY: 1080, bandHeight: 32))
        XCTAssertFalse(NotchForkLayout.isInsideTopBand(mouseY: 1080.5, screenMaxY: 1080, bandHeight: 32))
    }

    func testSideHoverDecisionEntersFromTheMarginAndExitsOnlyOutsideBoth() {
        let pill = CGRect(x: 100, y: 1048, width: 185, height: 32)
        let inPill = CGPoint(x: pill.midX, y: pill.midY)
        let inMargin = CGPoint(x: pill.minX - 16, y: pill.maxY)
        let outside = CGPoint(x: pill.maxX + 16, y: pill.midY)

        XCTAssertEqual(
            NotchForkLayout.sideHoverDecision(pillRect: pill, cursor: inMargin, isHovering: false, isClosed: true, inClosedHitArea: false),
            .enter)
        XCTAssertEqual(
            NotchForkLayout.sideHoverDecision(pillRect: pill, cursor: inPill, isHovering: false, isClosed: true, inClosedHitArea: true),
            .enter)
        XCTAssertEqual(
            NotchForkLayout.sideHoverDecision(pillRect: pill, cursor: outside, isHovering: false, isClosed: true, inClosedHitArea: false),
            .none)
        XCTAssertEqual(
            NotchForkLayout.sideHoverDecision(pillRect: pill, cursor: inPill, isHovering: false, isClosed: false, inClosedHitArea: true),
            .none)
        XCTAssertEqual(
            NotchForkLayout.sideHoverDecision(pillRect: pill, cursor: inMargin, isHovering: true, isClosed: true, inClosedHitArea: false),
            .none)
        XCTAssertEqual(
            NotchForkLayout.sideHoverDecision(pillRect: pill, cursor: outside, isHovering: true, isClosed: true, inClosedHitArea: true),
            .none)
        XCTAssertEqual(
            NotchForkLayout.sideHoverDecision(pillRect: pill, cursor: outside, isHovering: true, isClosed: true, inClosedHitArea: false),
            .exit)
    }

    func testSideHoverSweepPillThenMarginThenOutsideExits() {
        let pill = CGRect(x: 100, y: 1048, width: 185, height: 32)
        let onPill = CGPoint(x: pill.midX, y: pill.maxY)
        let inMargin = CGPoint(x: pill.minX - 10, y: pill.maxY)
        let outside = CGPoint(x: pill.minX - 17, y: pill.maxY)

        XCTAssertEqual(
            NotchForkLayout.sideHoverDecision(pillRect: pill, cursor: onPill, isHovering: false, isClosed: true, inClosedHitArea: true),
            .enter)
        XCTAssertEqual(
            NotchForkLayout.sideHoverDecision(pillRect: pill, cursor: onPill, isHovering: true, isClosed: true, inClosedHitArea: true),
            .none)
        XCTAssertEqual(
            NotchForkLayout.sideHoverDecision(pillRect: pill, cursor: inMargin, isHovering: true, isClosed: true, inClosedHitArea: false),
            .none)
        XCTAssertEqual(
            NotchForkLayout.sideHoverDecision(pillRect: pill, cursor: outside, isHovering: true, isClosed: true, inClosedHitArea: false),
            .exit)
    }
}
