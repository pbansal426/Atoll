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
        "\(Int(min(max(value, 0), 100).rounded()))%"
    }

    static func rpm(_ value: Double?) -> String {
        guard let value else { return "—" }
        return "\(Int(max(value, 0).rounded())) rpm"
    }

    static func fanPercent(_ reading: FanReading?) -> String {
        guard let reading else { return "—" }
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
/// whenever the strip is on.
enum StatsMonitoringPolicy {
    static func viewName(for view: NotchViews, stripEnabled: Bool) -> String {
        switch view {
        case .stats: return "stats"
        case .home: return stripEnabled ? "stats" : "other"
        default: return "other"
        }
    }
}

struct StatsStripView: View {
    @ObservedObject private var stats = StatsManager.shared
    @ObservedObject private var fans = FanMonitor.shared

    var body: some View {
        HStack(spacing: 18) {
            item("CPU", StatsStripFormatter.percent(stats.cpuUsage), .white)
            item("GPU", StatsStripFormatter.percent(stats.gpuUsage), .white)
            item("RAM", StatsStripFormatter.percent(stats.memoryUsage),
                 color(StatsStripFormatter.ramTint(stats.memoryBreakdown.pressure.level)))
            item("FAN", StatsStripFormatter.fanPercent(fans.reading), .white)
        }
        .font(.system(size: 11, weight: .medium, design: .monospaced))
        .frame(maxWidth: .infinity)
        .frame(height: StatsStripLayout.height)
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
