import Defaults
import SwiftUI

enum StatsStripTint: Equatable {
    case normal, warning, critical
}

enum StatsStripLayout {
    static let height: CGFloat = 20
}

enum StatsStripFormatter {
    /// StatsManager publishes usage as 0–100.
    static func percent(_ value: Double) -> String {
        guard value.isFinite else { return "—" }
        return "\(Int(min(max(value, 0), 100).rounded()))%"
    }

    static func rpm(_ value: Double?) -> String {
        guard let value, value.isFinite else { return "—" }
        return "\(Int(max(value, 0).rounded())) rpm"
    }

    static func fanPercent(_ reading: FanReading?) -> String {
        guard let reading, reading.fraction.isFinite else { return "—" }
        return "\(Int((min(max(reading.fraction, 0), 1) * 100).rounded()))%"
    }

    static func ramTint(_ level: MemoryPressureLevel) -> StatsStripTint {
        switch level {
        case .normal: return .normal
        case .warning: return .warning
        case .critical: return .critical
        }
    }
}

/// StatsManager only samples while it believes the stats tab is showing. The
/// strip needs the same numbers on the home view, so home counts as "stats"
/// whenever the strip is on. Pinned wings need them on every view.
enum StatsMonitoringPolicy {
    static func viewName(for view: NotchViews, stripEnabled: Bool, pinned: Bool) -> String {
        if pinned { return "stats" }
        switch view {
        case .stats: return "stats"
        case .home: return stripEnabled ? "stats" : "other"
        default: return "other"
        }
    }
}

enum StatsStripItem: Hashable {
    case cpu, gpu, memory, fan
}

struct StatsStripView: View {
    @EnvironmentObject var vm: DynamicIslandViewModel
    @ObservedObject private var stats = StatsManager.shared
    @ObservedObject private var fans = FanMonitor.shared
    @State private var openItem: StatsStripItem?

    var body: some View {
        HStack(spacing: 18) {
            button(.cpu, "CPU", StatsStripFormatter.percent(stats.cpuUsage), .white) {
                RankedProcessPopover(rankingType: .cpu)
            }
            button(.gpu, "GPU", StatsStripFormatter.percent(stats.gpuUsage), .white) {
                RankedProcessPopover(rankingType: .gpu)
            }
            button(.memory, "MEM", StatsStripFormatter.percent(stats.memoryBreakdown.pressure.percent ?? .nan),
                   color(StatsStripFormatter.ramTint(stats.memoryBreakdown.pressure.level))) {
                RankedProcessPopover(rankingType: .memory)
            }
            button(.fan, "FAN", StatsStripFormatter.fanPercent(fans.reading), .white) {
                FanDetailView()
            }
        }
        .font(.system(size: 11, weight: .medium, design: .monospaced))
        .frame(maxWidth: .infinity)
        .frame(height: StatsStripLayout.height)
        .onChange(of: openItem) { _, item in vm.isStatsPopoverActive = item != nil }
        .onDisappear { vm.isStatsPopoverActive = false }
    }

    private func button<Content: View>(_ which: StatsStripItem, _ label: String, _ value: String, _ tint: Color,
                                       @ViewBuilder popover: @escaping () -> Content) -> some View {
        Button { openItem = which } label: { item(label, value, tint) }
            .buttonStyle(.plain)
            .popover(isPresented: Binding(get: { openItem == which },
                                          set: { if !$0 { openItem = nil } }),
                     arrowEdge: .bottom) { popover() }
    }

    private func item(_ label: String, _ value: String, _ tint: Color) -> some View {
        HStack(spacing: 4) {
            Text(label).foregroundStyle(.gray)
            Text(value).foregroundStyle(tint)
        }
    }

    private func color(_ tint: StatsStripTint) -> Color {
        switch tint {
        case .normal: return .green
        case .warning: return .yellow
        case .critical: return .red
        }
    }
}
