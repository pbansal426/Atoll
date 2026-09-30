import SwiftUI
import Combine

/// Fan popover: per-fan speed plus smctl profile, thermal, throttling and keeper state.
struct FanDetailView: View {
    @StateObject private var model = SmctlStatusModel()
    @ObservedObject private var fans = FanMonitor.shared

    private let cardBackground = Color(nsColor: .windowBackgroundColor).opacity(0.65)

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Fans")
                .font(.headline)

            VStack(alignment: .leading, spacing: 8) {
                if let list = model.fan?.fans, !list.isEmpty {
                    ForEach(list, id: \.index) { fan in
                        fanRow(fan)
                    }
                } else {
                    Text("—").foregroundColor(.secondary)
                }
            }

            Divider()

            VStack(alignment: .leading, spacing: 6) {
                statusRow(profileText)
                statusRow("Thermal: \(model.power?.thermalPressure ?? "—")")
                statusRow(throttlingText)
                statusRow("Keeper: \(model.keeperEvent ?? "no events")")
            }
        }
        .padding(16)
        .frame(width: 320, alignment: .leading)
        .background(cardBackground, in: RoundedRectangle(cornerRadius: 12))
        .onAppear { model.refresh() }
        .onReceive(Timer.publish(every: 3, on: .main, in: .common).autoconnect()) { _ in
            model.refresh()
        }
    }

    private func fanRow(_ fan: SmctlFan) -> some View {
        let reading = FanReading(rpm: Double(fan.actualRPM), maxRPM: Double(fan.maximumRPM))
        return HStack {
            Text("Fan \(fan.index)")
                .font(.subheadline.weight(.medium))
            Spacer()
            Text(StatsStripFormatter.fanPercent(reading))
                .font(.system(.subheadline, design: .monospaced).weight(.semibold))
            Text("\(fan.actualRPM) rpm")
                .font(.caption)
                .foregroundColor(.secondary)
            Text("\(fan.minimumRPM)–\(fan.maximumRPM)")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }

    private func statusRow(_ text: String) -> some View {
        Text(text)
            .font(.caption)
            .foregroundColor(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var profileText: String {
        guard let status = model.fan else { return "Profile: —" }
        var text = "Profile: \(status.profile)"
        if let first = status.fans.first, first.mode == "auto", status.profile != "auto" {
            text += " (fans: \(first.mode))"
        }
        return text
    }

    private var throttlingText: String {
        guard let power = model.power else { return "Throttling: —" }
        if power.throttlingRecorded, let limit = power.speedLimitPercent {
            return "Throttling: limited to \(limit)%"
        }
        return "Throttling: none recorded"
    }
}
