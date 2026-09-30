import Foundation

struct SmctlFan: Equatable {
    let index: Int
    let actualRPM: Int
    let minimumRPM: Int
    let maximumRPM: Int
    let mode: String
}

struct SmctlFanStatus: Equatable {
    let profile: String
    let fans: [SmctlFan]
}

struct SmctlPowerStatus: Equatable {
    let thermalPressure: String
    let throttlingRecorded: Bool
    let speedLimitPercent: Int?
}

/// Parses smctl's read-only status output. The app never runs smctl write commands.
enum SmctlStatusParser {
    static func fan(_ data: Data) -> SmctlFanStatus? {
        guard let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let profile = root["profile"] as? String,
              let fans = root["fans"] as? [[String: Any]] else { return nil }
        let parsed = fans.compactMap { fan -> SmctlFan? in
            guard let index = fan["index"] as? Int,
                  let actual = fan["actualRPM"] as? Int,
                  let min = fan["minimumRPM"] as? Int,
                  let max = fan["maximumRPM"] as? Int else { return nil }
            return SmctlFan(index: index, actualRPM: actual, minimumRPM: min, maximumRPM: max,
                            mode: fan["mode"] as? String ?? "unknown")
        }
        return SmctlFanStatus(profile: profile, fans: parsed)
    }

    static func power(_ data: Data) -> SmctlPowerStatus? {
        guard let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let pressure = root["thermalPressure"] as? String else { return nil }
        let cpu = root["cpu"] as? [String: Any]
        return SmctlPowerStatus(
            thermalPressure: pressure,
            throttlingRecorded: cpu?["recorded"] as? Bool ?? false,
            speedLimitPercent: cpu?["speedLimit"] as? Int
        )
    }

    /// Last non-empty keeper log line as "YYYY-MM-DD HH:MM — message".
    static func lastKeeperEvent(_ log: String) -> String? {
        guard let line = log.split(separator: "\n").last(where: { !$0.trimmingCharacters(in: .whitespaces).isEmpty }) else { return nil }
        let parts = line.split(separator: " ", maxSplits: 3).map(String.init)
        guard parts.count == 4 else { return String(line) }
        return "\(parts[0]) \(parts[1].prefix(5)) — \(parts[3])"
    }
}

/// Runs the read-only smctl status commands off the main thread for the fan popover.
final class SmctlStatusModel: ObservableObject {
    @Published private(set) var fan: SmctlFanStatus?
    @Published private(set) var power: SmctlPowerStatus?
    @Published private(set) var keeperEvent: String?

    static let smctlPath = "/opt/homebrew/bin/smctl"
    static let keeperLogPath = "/Library/Logs/smctl-keeper.log"

    private var isRefreshing = false

    func refresh() {
        guard !isRefreshing else { return }
        isRefreshing = true
        DispatchQueue.global(qos: .userInitiated).async {
            let fan = Self.run(["fan", "status", "--json"]).flatMap(SmctlStatusParser.fan)
            let power = Self.run(["power", "status", "--json"]).flatMap(SmctlStatusParser.power)
            let log = (try? String(contentsOfFile: Self.keeperLogPath, encoding: .utf8)) ?? ""
            let event = SmctlStatusParser.lastKeeperEvent(log)
            DispatchQueue.main.async {
                self.fan = fan
                self.power = power
                self.keeperEvent = event
                self.isRefreshing = false
            }
        }
    }

    private static func run(_ arguments: [String]) -> Data? {
        guard FileManager.default.isExecutableFile(atPath: smctlPath) else { return nil }
        let process = Process()
        process.executableURL = URL(fileURLWithPath: smctlPath)
        process.arguments = arguments
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()
        do { try process.run() } catch { return nil }
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        return process.terminationStatus == 0 ? data : nil
    }
}
