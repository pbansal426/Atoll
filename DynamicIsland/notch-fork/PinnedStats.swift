import Defaults
import SwiftUI

enum PinnedValue: String, CaseIterable, Defaults.Serializable, Identifiable {
    case cpu, gpu, ram, fan, clock
    var id: String { rawValue }
    var title: String {
        switch self {
        case .cpu: return "CPU"
        case .gpu: return "GPU"
        case .ram: return "Memory pressure"
        case .fan: return "Fan"
        case .clock: return "Clock"
        }
    }
}

struct PinnedSnapshot {
    let cpu: Double
    let gpu: Double
    let memoryPressure: Double?
    let fan: FanReading?
    let now: Date
}

enum PinnedLayout {
    static let wingWidth: CGFloat = 52
}

enum PinnedFormatter {
    static func text(_ value: PinnedValue, _ s: PinnedSnapshot, calendar: Calendar = .current) -> String {
        switch value {
        case .cpu: return "CPU " + StatsStripFormatter.percent(s.cpu)
        case .gpu: return "GPU " + StatsStripFormatter.percent(s.gpu)
        case .ram: return "MEM " + StatsStripFormatter.percent(s.memoryPressure ?? .nan)
        case .fan: return "FAN " + StatsStripFormatter.fanPercent(s.fan)
        case .clock:
            let parts = calendar.dateComponents([.hour, .minute], from: s.now)
            let hour12 = ((parts.hour ?? 0) + 11) % 12 + 1
            return String(format: "%d:%02d", hour12, parts.minute ?? 0)
        }
    }
}

/// Closed-notch wings: one pinned value each side of the notch.
struct PinnedStatsView: View {
    @EnvironmentObject var vm: DynamicIslandViewModel
    @ObservedObject private var stats = StatsManager.shared
    @ObservedObject private var fans = FanMonitor.shared
    @Default(.pinnedLeft) private var left
    @Default(.pinnedRight) private var right

    private func snapshot(at now: Date) -> PinnedSnapshot {
        PinnedSnapshot(cpu: stats.cpuUsage, gpu: stats.gpuUsage,
                       memoryPressure: stats.memoryBreakdown.pressure.percent, fan: fans.reading, now: now)
    }

    var body: some View {
        HStack(spacing: 0) {
            wing(left, alignment: .leading)
            Rectangle().fill(.black).frame(width: vm.closedNotchSize.width)
            wing(right, alignment: .trailing)
        }
        .frame(height: vm.effectiveClosedNotchHeight)
    }

    @ViewBuilder
    private func wing(_ value: PinnedValue, alignment: Alignment) -> some View {
        if value == .clock {
            TimelineView(.everyMinute) { context in
                wingLabel(PinnedFormatter.text(.clock, snapshot(at: context.date)), alignment: alignment)
            }
        } else {
            wingLabel(PinnedFormatter.text(value, snapshot(at: Date())), alignment: alignment)
        }
    }

    private func wingLabel(_ text: String, alignment: Alignment) -> some View {
        Text(text)
            .font(.system(size: 10, weight: .semibold, design: .monospaced))
            .foregroundStyle(.white)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .padding(.horizontal, 4)
            .frame(width: PinnedLayout.wingWidth, alignment: alignment)
    }
}
