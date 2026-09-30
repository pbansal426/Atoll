import SwiftUI

/// Closed-notch activity while the fans are at or above half their maximum:
/// a fan glyph left of the notch, current RPM right of it.
struct FanLiveActivity: View {
    @EnvironmentObject var vm: DynamicIslandViewModel
    @ObservedObject private var fans = FanMonitor.shared
    @State private var isExpanded = false

    private let rightWingWidth: CGFloat = 64

    private var wingHeight: CGFloat { max(0, vm.effectiveClosedNotchHeight - 12) }

    @ViewBuilder
    private var fanGlyph: some View {
        let glyph = Image(systemName: "fan.fill")
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(.orange)
        if #available(macOS 15.0, *) {
            glyph.symbolEffect(.rotate, isActive: true)
        } else {
            glyph
        }
    }

    var body: some View {
        HStack(spacing: 0) {
            Color.clear
                .overlay(alignment: .leading) {
                    if isExpanded {
                        fanGlyph
                    }
                }
                .frame(width: isExpanded ? wingHeight + 10 : 0, height: wingHeight)

            Rectangle()
                .fill(.black)
                .frame(width: vm.closedNotchSize.width)

            Color.clear
                .overlay(alignment: .trailing) {
                    if isExpanded {
                        Text(StatsStripFormatter.rpm(fans.reading?.rpm))
                            .font(.system(size: 11, weight: .semibold, design: .monospaced))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                            .fixedSize()
                    }
                }
                .frame(width: isExpanded ? rightWingWidth : 0, height: wingHeight)
        }
        .frame(height: vm.effectiveClosedNotchHeight)
        .onAppear { withAnimation(.smooth(duration: 0.4)) { isExpanded = true } }
    }
}
